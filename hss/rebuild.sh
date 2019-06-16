#!/bin/sh

docker container prune -f
docker rmi tig4605246/oaicn:1.1
docker build -t tig4605246/oaicn:1.1 --force-rm=true --rm=true .