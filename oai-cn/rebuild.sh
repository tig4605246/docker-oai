#!/bin/sh

docker container rm oaicn -f
docker rmi tig4605246/oaicn:1.1
mv ~/kubernetes/go/src/snap-hook-for-docker/cmd/hook/hook ./
docker build -t tig4605246/oaicn:1.1 --force-rm=true --rm=true .
