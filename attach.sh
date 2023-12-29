#!/bin/zsh
container=$(docker ps|grep $1 | awk '{ print $1 }')
echo "Attaching..."
shell=

docker exec -it $container ${2:-/bin/bash}
