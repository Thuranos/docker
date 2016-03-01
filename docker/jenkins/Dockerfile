FROM jenkins:latest
 
ENV DEBIAN_FRONTEND noninteractive
 
USER root

RUN curl -sSL https://get.docker.com/ | sh && rm -rf /var/lib/apt/lists/*

COPY ./jenkins_utils/plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

COPY ./jenkins_utils/execute.sh /opt/execute.sh
RUN chmod +x /opt/execute.sh

COPY ./jenkins_utils/database.properties_test /opt/database.properties
COPY ./jenkins_utils/database.properties_prod /opt/deployment/database.properties
COPY ./jenkins_utils/glazer-deploy.sh /opt/deployment/glazer-deploy.sh
COPY ./jenkins_utils/Dockerfile_webapp /opt/deployment/Dockerfile
COPY ./jenkins_utils/cdb-jenkins /var/jenkins_home/jobs/cdb-jenkins

ENV DOCKER_HOST tcp://dind:4242
