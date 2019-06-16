#!/bin/sh
# Entrypoint for hss container
# sleep 10
# snap install core --channel=edge

# while ! kill -0 $(pidof snapd) 2>/dev/null; do
#   echo "Waiting for snapd to start."
#   sleep 3
# done
HOST=`hostname`
cp /etc/hosts /root/hosts_new
sed -i "1s/^/127.0.0.1 ${HOST}.openair4G.eur ${HOST} hss \n127.0.0.1 ${HOST}.openair4G.eur ${HOST} mme \n/" ~/hosts_new
cp -f /root/hosts_new /etc/hosts
# snap install oai-cn --channel=edge --devmode
# sed -i -r "31s/.{1}//" /var/snap/oai-cn/28/hss.conf
# sed -i '30s/^/#/' /var/snap/oai-cn/28/hss.conf
# sed -i 's/127.0.0.1/mysql/g' /var/snap/oai-cn/28/hss.conf

# sed -i 's/PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config
# sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
# service sshd restart 

# oai-cn.hss-init
# oai-cn.hss-start
# oai-cn.hss-stop
# oai-cn.hss-init
# oai-cn.hss-start

# Suspend the container
# while :; do echo '.'; sleep 5 ; done