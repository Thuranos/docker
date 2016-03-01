#!/bin/bash

# This script can start a container on a remote glazer-container-agent.
#
# Examples:
#
# $ ./glazer-deploy.sh --host 127.0.0.1 --port 65000 hello hello-world
#        Start a container from the hello-world:latest image with the name hello.
#
# $ ./glazer-deploy.sh --host 127.0.0.1 --port 65000 --link mysql:db mywebapp mytomcat:1.2
#        Start and link the container with the container mysql as db.
#        Be sure mysql is running or you will get an "Internal error communicating with Docker".
#
# $ ./glazer-deploy.sh --host localhost --port 65000 --publish all webapp webapp-image
#        Start the container and publish all ports.
#        --publish all is recommended if you don't know the port range of the glazer container agent.
#
# Recall that if the image does not exist on the glazer container agent it must be pulled from a registry so it may be long.

USAGE="usage: glazer-deploy.sh [OPTIONS] CONTAINER_NAME IMAGE
--env      add env variable as name=value
--help     Print help
--host     the glazer container agent host address, default localhost
--link     Add link to another container
--port     the glazer container agent port number, default 80
--publish  the port mapping as 'host:container' or 'all'"

if [[ $# -lt 2 ]]
then
    echo "$USAGE"
    exit -1
fi

# Init default values
LINKS=()
PORTS=()
HOST="localhost"
PORT="80"
MAP_EXPOSED_PORTS="false"

# Parse options
while [[ $# -gt 2 ]]
do
key="$1"
case $key in
    --env)
    ENV="$2"
    if [[ $ENV == *"="* ]]
    then
        ENVS+=(${ENV%=*})
        ENVS+=(${ENV#*=})
    else
        echo "$USAGE"
        exit -1
    fi
    shift
    ;;
    --host)
    HOST="$2"
    shift
    ;;
     --port)
    PORT="$2"
    shift
    ;;
    --link)
    LINK_NAME="$2"
    if [[ $LINK_NAME == *":"* ]]
    then
        LINK_ALIAS=${LINK_NAME#*:}
        LINK_NAME=${LINK_NAME%:*}
    else
        LINK_ALIAS=$LINK_NAME
    fi
    LINKS+=($LINK_NAME)
    LINKS+=($LINK_ALIAS)
    shift
    ;;
    --publish)
    HOST_PORT="$2"
    if [[ $HOST_PORT == "all" ]]
    then
        MAP_EXPOSED_PORTS="true"
    elif [[ $HOST_PORT == *":"* ]]
    then
        CONTAINER_PORT=${HOST_PORT#*:}
        HOST_PORT=${HOST_PORT%:*}
        PORTS+=($HOST_PORT)
        PORTS+=($CONTAINER_PORT)
    else
        CONTAINER_PORT=$HOST_PORT
        PORTS+=($HOST_PORT)
        PORTS+=($CONTAINER_PORT)
    fi
    shift
    ;;
    --help)
    echo "$USAGE"
    exit 0 
    ;;
    -*)
    echo "unknown option"
    echo "$USAGE"
    exit -1
    ;;
    *)
    ;;
esac
shift
done

# Check for container name and image parameters
if [[ $# -lt 2 ]]
then
    echo "Error: No container name or image provided"
    echo "$USAGE"
    exit -1
fi

# Get container name
CONTAINER_NAME="$1"
# Ensure container name is not empty
if [[ -z $CONTAINER_NAME ]]
then
    echo "Error: invalid container name: $CONTAINER_NAME"
    exit -1
fi

# Get image name and tag
IMAGE_NAME="$2"
if [[ $IMAGE_NAME == *":"* ]]
then
      IMAGE_TAG=${IMAGE_NAME#*:}
       IMAGE_NAME=${IMAGE_NAME%:*}
else
       IMAGE_TAG=latest
fi

# Notify the glazer-container-agent
CONTAINER_AGENT_ENDPOINT=$HOST:$PORT

# Format links as json array
LINK_JSON="["
for ((i = 0; i < ${#LINKS[@]}; i += 2))
do
    LINK_JSON+="{\"name\":\"${LINKS[$i]}\", \"alias\":\"${LINKS[$i+1]}\"},"
done
# Remove the last comma if more than one element
if [[ ${#LINKS[@]} -gt 0 ]]
then
    LINK_JSON=${LINK_JSON::-1}
fi
LINK_JSON+="]"

# Format ports as json object
PORT_JSON="{"
for ((i = 0; i < ${#PORTS[@]}; i += 2))
do
    PORT_JSON+="\"${PORTS[$i+1]}\":\"${PORTS[$i]}\","
done
# Remove the last comma if more than one element
if [[ ${#PORTS[@]} -gt 0 ]]
then
    PORT_JSON=${PORT_JSON::-1}
fi
PORT_JSON+="}"

# Format env variables as json array
ENV_JSON="["
for ((i = 0; i < ${#ENVS[@]}; i += 2))
do
    ENV_JSON+="{\"key\":\"${ENVS[$i]}\", \"value\":\"${ENVS[$i+1]}\"},"
done
# Remove the last comma if more than one element
if [[ ${#ENVS[@]} -gt 0 ]]
then
    ENV_JSON=${ENV_JSON::-1}
fi
ENV_JSON+="]"

BODY="{\"name\":\"$CONTAINER_NAME\", \"image\":{\"remote\":\"docker.io\", \"name\":\"$IMAGE_NAME\", \"tag\":\"$IMAGE_TAG\", \"type\":8}, \"options\":{\"type\":\"COMMAND\", \"links\":$LINK_JSON, \"mapExposedPorts\":$MAP_EXPOSED_PORTS, \"portsMap\":$PORT_JSON, \"envVariables\":$ENV_JSON}}"

# Pull the new image and start the container
echo "Starting container $CONTAINER_NAME from image $IMAGE_NAME:$IMAGE_TAG..."
RESPONSE=$(curl -s -w "%{http_code}" -X POST -H "Content-Type:application/json" -d "$BODY" $CONTAINER_AGENT_ENDPOINT/container/start)

# Get the response code. Should be the last 3 characters
HTTP_CODE=${RESPONSE: -3}

if [[ $HTTP_CODE = "000" ]]
then
    echo "Unable to connect to host $HOST:$PORT"
    exit -1
fi

if [[ $HTTP_CODE = "409" ]]
then
    # Retrieve the container id from the response
    CONTAINER_ID=$(echo $RESPONSE | sed 's/.*by container \([a-z0-9]*\)\..*/\1/')
    echo "Name conflict: $CONTAINER_ID already has the name $CONTAINER_NAME."
    # Stop the container
    echo "Stopping the container $CONTAINER_ID..."
    curl -s -X POST $CONTAINER_AGENT_ENDPOINT/container/stop/$CONTAINER_ID > /dev/null
    # Remove the container
    echo "Removing the container $CONTAINER_ID..."
    curl -s -X DELETE $CONTAINER_AGENT_ENDPOINT/container/$CONTAINER_ID > /dev/null
    # Try to start the container once again
    RESPONSE=$(curl -s -w "%{http_code}" -X POST -H "Content-Type:application/json" -d "$BODY" $CONTAINER_AGENT_ENDPOINT/container/start)
    HTTP_CODE=${RESPONSE: -3}
    if [[ $HTTP_CODE != "200" ]]
    then
        echo "Unable to start the container"
        echo "${RESPONSE::-3}" | sed 's/.*\\"message\\":\\"\(.*\)\\".*}"/\1/'
        exit -1
    fi
fi

if [[ $HTTP_CODE != "200" ]]
then
    echo "An error occured:"
    echo "${RESPONSE::-3}" | sed 's/.*\\"message\\":\\"\(.*\)\\".*}"/\1/'
    exit -1
fi

PORT_MAPPING=$(echo "${RESPONSE::-3}" | sed 's/.*"portsMap":{\(["0-9:,]*\)}.*/\1/')
echo "Container started with success. Port mapping: $PORT_MAPPING"
exit 0
