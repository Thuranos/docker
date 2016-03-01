#!/bin/bash

set -x 

docker pull rlarroque/cdb_ut

#Stop and rm running containers
for container_id in $(docker ps  --filter="name=cdb_ut" -q);
	do docker stop $container_id && docker rm $container_id;
done

#rm stopped containers
for container_id in $(docker ps  --filter="name=cdb_ut" -q -a);
	do docker rm $container_id;
done

docker create --name cdb_ut rlarroque/cdb_ut
docker cp /var/jenkins_home/jobs/cdb-jenkins/workspace/ cdb_ut:/opt/test
docker start -a cdb_ut
