FROM ubuntu:15.10

RUN apt-get update
RUN apt-get -y install openjdk-8-jdk maven
RUN update-ca-certificates -f

ENV MYSQL_HOST tcp://dind:3306

ENTRYPOINT mvn clean install -DskipITs -f /opt/test/computer_database/pom.xml
