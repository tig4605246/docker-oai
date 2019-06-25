#!/bin/sh

docker container prune -f
docker rmi tig4605246/oairan:1.0
cp ~/kubernetes/go/src/snap-hook-for-docker/cmd/hook/hook ./
docker build -t tig4605246/oairan:1.0 --force-rm=true --rm=true .