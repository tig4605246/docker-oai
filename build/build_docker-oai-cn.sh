#! /bin/sh
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
# file          build_dokcer-oai-cn.sh
# brief         OAI-CN-ALL-IN-ONE automated Docker deployment 
# author        Mihai IDU (C) - 2019 mihai.idu@eurecom.fr


set -e

CONTNAME=oai-cn-all-in-one
IMGNAME=oai-cn-all-in-one-image
RELEASE=16.04

SUDO=""
if [ -z "$(id -Gn|grep docker)" ] && [ "$(id -u)" != "0" ]; then
    SUDO="sudo"
fi

if [ "$(which docker)" = "/snap/bin/docker" ]; then
    export TMPDIR="$(readlink -f ~/snap/docker/current)"
	# we need to run the snap once to have $SNAP_USER_DATA created
	/snap/bin/docker >/dev/null 2>&1
fi

BUILDDIR=$(mktemp -d)

usage() {
    echo "usage: $(basename $0) [options]"
    echo
    echo "  -c|--containername <name> (default: oai-cn-all-in-one)"
    echo "  -i|--imagename <name> (default: oai-cn-all-in-one)"
    rm_builddir
}

print_info() {
    echo
    echo "use: $SUDO docker exec -it $CONTNAME <command> ... to run a command inside this container"
    echo
    echo "to remove the container use: $SUDO docker rm -f $CONTNAME"
    echo "to remove the related image use: $SUDO docker rmi $IMGNAME"
}

clean_up() {
    sleep 1
    $SUDO docker rm -f $CONTNAME >/dev/null 2>&1 || true
    $SUDO docker rmi $IMGNAME >/dev/null 2>&1 || true
    $SUDO docker rmi $($SUDO docker images -f "dangling=true" -q) >/dev/null 2>&1 || true
    rm_builddir
}

rm_builddir() {
    rm -rf $BUILDDIR || true
    exit 0
}

trap clean_up 1 2 3 4 9 15

while [ $# -gt 0 ]; do
       case "$1" in
               -c|--containername)
                       [ -n "$2" ] && CONTNAME=$2 shift || usage
                       ;;
               -i|--imagename)
                       [ -n "$2" ] && IMGNAME=$2 shift || usage
                       ;;
               -h|--help)
                       usage
                       ;;
               *)
                       usage
                       ;;
       esac
       shift
done

if [ -n "$($SUDO docker ps -f name=$CONTNAME -q)" ]; then
    echo "Container $CONTNAME already running!"
    print_info
    rm_builddir
fi

DOCKERID=$SUDO docker ps -aqf name=$CONTNAME

if [ -z "$($SUDO docker images|grep $IMGNAME)" ]; then
    cat << EOF > $BUILDDIR/Dockerfile
FROM ubuntu:$RELEASE
ENV container docker
ENV PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN apt-get update &&\
 DEBIAN_FRONTEND=noninteractive\
 apt-get install -y fuse snapd snap-confine squashfuse sudo &&\
 apt-get clean &&\
 dpkg-divert --local --rename --add /sbin/udevadm &&\
 ln -s /bin/true /sbin/udevadm
RUN apt-get install -y apt-utils
RUN apt-get install -y net-tools
RUN apt-get install -y iputils-ping
RUN apt-get install -y vim
RUN systemctl enable snapd
VOLUME ["/sys/fs/cgroup"]
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
EOF
    $SUDO docker build -t $IMGNAME --force-rm=true --rm=true $BUILDDIR || clean_up
fi

# start the detached container
$SUDO docker run \
    --name=$CONTNAME \
    -ti \
    --tmpfs /run \
    --tmpfs /run/lock \
    --tmpfs /tmp \
    --cap-add SYS_ADMIN \
    --device=/dev/fuse \
    --security-opt apparmor:unconfined \
    --security-opt seccomp:unconfined \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v /lib/modules:/lib/modules:ro \
    -h ubuntu \
    -d $IMGNAME || clean_up

# wait for snapd to start
TIMEOUT=20
SLEEP=3
echo -n "Waiting $(($TIMEOUT*3)) seconds for snapd startup"
while [ -z "$($SUDO docker exec $CONTNAME pgrep snapd)" ]; do
    echo -n "."
    sleep $SLEEP || clean_up
    if [ "$TIMEOUT" -le "0" ]; then
        echo " Timed out!"
        clean_up
    fi
    TIMEOUT=$(($TIMEOUT-1))
done

$SUDO docker exec -it $CONTNAME /bin/bash -c "snap install core --channel=edge" 

# ====
# Modifing the /etc/hosts for the hss and mme realm
# ====
$SUDO docker exec -it $CONTNAME /bin/bash -c "echo '127.0.0.1 ubuntu.openair4G.eur ubuntu hss' >> /etc/hosts"
$SUDO docker exec -it $CONTNAME /bin/bash -c "echo '127.0.0.1 ubuntu.openair4G.eur ubuntu mme' >> /etc/hosts"

$SUDO docker exec -it $CONTNAME /bin/bash -c "snap install oai-cn --channel=edge --devmode"
echo "container $CONTNAME started with ..."
echo ""
echo "-------------------------------------------------------------"
echo "     Listing the installed snaps installed on the Docker     "
echo "-------------------------------------------------------------"
echo ""
$SUDO docker exec $CONTNAME snap list


print_info
rm_builddir