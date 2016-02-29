FROM jenkins:latest
 
ENV DEBIAN_FRONTEND noninteractive
 
USER root

RUN curl -sSL https://get.docker.com/ | sh && rm -rf /var/lib/apt/lists/*

COPY ./plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

COPY ./execute.sh /opt/execute.sh
RUN chmod +x /opt/execute.sh

COPY ./database.properties /opt/database.properties

COPY ./cdb-jenkins /var/jenkins_home/jobs/cdb-jenkins

ENV DOCKER_HOST tcp://dind:4242
