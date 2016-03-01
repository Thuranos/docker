#!/bin/bash

echo -n "password : "
read -s password

docker-compose up -d
docker exec jenkins docker login --username="rlarroque" --email="rom.larroque@gmail.com" --password="$password"
