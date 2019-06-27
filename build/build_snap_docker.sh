#! /bin/bash
################################################################################
# Licensed to the Mosaic5G under one or more contributor license
# agreements. See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.
# The Mosaic5G licenses this file to You under the
# Apache License, Version 2.0  (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#  
#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# -------------------------------------------------------------------------------
#   For more information about the:
#       
#
#
################################################################################
# file          build_snap_docker.sh
# brief         Build and renew the local image  
# author        Kevin Hsu (C) - 2019 hsuh@eurecom.fr

REPO_NAME="tig4605246"
OAICN="${REPO_NAME}/oaicn"
OAIRAN="${REPO_NAME}/oairan"
TAG_TEST="test"
OAICN_CONTAINER="oaicn-test"
OAIRAN_CONTAINER="oairan-test"
RELEASE_TAG="latest"

# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
contains() {
    string="$1"
    substring="$2"

    if echo "$string" | $(type -p ggrep grep | head -1) -F -- "$substring" >/dev/null; then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

build_hook(){
    go build ${GOPATH}/src/oai-snap-in-docker/cmd/hook/
    mv ${GOPATH}/src/oai-snap-in-docker/cmd/hook/hook ./
}

# Recreate oai-cn base image
build_cn_base(){
    cd ../oai-cn/
    cp ../build/hook ./
    cp ../build/conf.yaml ./
    docker build -t ${OAICN}:${TAG_TEST} --force-rm=true --rm=true .  |& tee build.log
}

# Recreate oai-ran base image
build_ran_base(){
    cd oai-ran/
    cp ../build/hook ./
    cp ../build/conf.yaml ./
    docker build -t ${OAIRAN}:${TAG_TEST} --force-rm=true --rm=true . |& tee build.log
}

# Build oai-cn with base image
build_cn(){
    build_cn_base
    docker run --name=${OAICN_CONTAINER} -ti --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /lib/modules:/lib/modules:ro -h ubuntu -d ${OAICN}:${TAG_TEST}
    RET=1
    echo "Installing snaps..."
    while  [ ${RET} -ne 0 ] ;
    do
        sleep 5
        LIST=`docker exec ${OAICN_CONTAINER} snap list`
        contains "${LIST}" "oai-cn"
        RET=$?
        
    done
    docker commit ${OAICN_CONTAINER} ${OAICN}:${RELEASE_TAG}
    docker stop ${OAICN_CONTAINER}
    docker container rm ${OAICN_CONTAINER} -f
    docker image prune -f
    echo "Now ${OAICN}:${RELEASE_TAG} is ready"
}

# Build oai-ran with base image
build_ran(){
    build_cn_base
    docker run --name=${OAIRAN_CONTAINER} -ti --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /lib/modules:/lib/modules:ro -h ubuntu -d ${OAIRAN}:${TAG_TEST}
    RET=1
    echo "Installing snaps..."
    while  [ ${RET} -ne 0 ] ;
    do
        sleep 5
        LIST=`docker exec ${OAIRAN_CONTAINER} snap list`
        contains "${LIST}" "oai-cn"
        RET=$?
    done
    echo "snap installed"
    docker commit ${OAIRAN_CONTAINER} ${OAIRAN}:${RELEASE_TAG}
    docker stop ${OAIRAN_CONTAINER}
    docker container rm ${OAIRAN_CONTAINER} -f
    docker image prune -f
    echo "Now ${OAIRAN}:${RELEASE_TAG} is ready"
}

clean_up(){
    rm hook
}

clean_all(){
    docker stop ${OAICN_CONTAINER}
    docker container rm ${OAICN_CONTAINER} -f
    docker stop ${OAIRAN_CONTAINER}
    docker container rm ${OAIRAN_CONTAINER} -f
    docker rmi ${OAIRAN}:${TAG_TEST}
    docker rmi ${OAICN}:${TAG_TEST}
    docker image prune -f
}

main() {
    RELEASE_TAG=${2}
    case ${1} in
        build-cn)
            build_hook
            build_cn  
        ;;
        build-ran)
            build_hook
            build_ran
        ;;
        flexran)
        # Work in progress
        ;;
        ll-mec)
        # Work in progress
        ;;
        clean-all)
            clean_all
        ;;
        stop)
            stop
        ;;
        *)
            echo "Description:"
            echo "This Script will remove the old docker snap image and build a new one"
            echo "tested with 16.04 Ubuntu"
            echo "./build_snap_docker.sh [cn|ran|flexran|ll-mec] [release tag(default if latest)]"
            echo "Example: ./build_snap_docker.sh cn nightly"
            exit 0
        ;;
    esac
    clean_up

}
main ${1} ${2}