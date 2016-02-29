#!/bin/bash

docker build -t cdb_ut .
docker tag cdb_ut rlarroque/cdb_ut
docker push rlarroque/cdb_ut
