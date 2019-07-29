#!/bin/bash

# Extra for Ubuntu 16.04
# 1、kubectl edit cm coredns -n kube-system
# 2、delete ‘loop’ ,save and exit
# 3、kubectl -n kube-system delete pod -l k8s-app=kube-dns
# Python API for creating namespace
# core_v1_api.py create_namespace
# kubectl taint node aiyu-lab node-role.kubernetes.io/master:NoSchedule-

start(){
    # Create Single Node Kubernetes automatically, run this with normal user
    STARTUP_TYPE=${1}
    echo ${STARTUP_TYPE}
    sudo rm -r .kube/
    sudo ln -s /run/resolvconf/ /run/systemd/resolve
    sudo swapoff -a

    echo "Are we creating Kubernetes with ${STARTUP_TYPE} POD network?"
    # POD network is different between each cni plugin
    if [ ${STARTUP_TYPE} == "flannel" ]; then
        sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    elif [ ${STARTUP_TYPE} == "calico" ]; then
        sudo kubeadm init --pod-network-cidr=192.168.0.0/16
    fi

    echo "Adding config to ${HOME}"
    echo "Sleep wait 1 sec"
    sleep 1

    mkdir -p $HOME/.kube
    sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown 1000:1000 $HOME/.kube/config

    echo "Sleep to wait master booting up"
    sleep 1

    #flannel
    if [ ${STARTUP_TYPE} == "flannel" ]; then
        echo "Apply flannel"
        kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml 
    elif [ ${STARTUP_TYPE} == "calico" ]; then 
        kubectl apply -f \
        https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
    fi

    echo "wait for kubernetes is ready"
    sleep 10

    echo "Schedule POD on Master"
    kubectl taint node ${HOSTNAME} node-role.kubernetes.io/master:NoSchedule-

    # Should be revised for proper use
    if [ ${STARTUP_TYPE} == "jkl" ]; then
        echo "add privileged account for tiller"
        kubectl apply -f ./tillerRole.yaml    


        echo "Init helm"
        helm init --service-account tiller --history-max 200


        # echo "Grant kube-system RBAC for tiller (bypass access problem)"
        # kubectl create serviceaccount --namespace kube-system tiller
        # kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
        # kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    fi
    echo "Done, good to go"
}


stop(){
    echo "Stopping Kubernetes"
    sudo kubeadm reset -f 
    echo "Kubernetes Stopped by stop()"
}



main() {
    if [ `id -u` = "0" ]; then
        echo "please run this as normal user and  set up sudo without password"
        return -1
    fi
    case ${1} in
        start)
            start ${2}
        ;;
        stop)
            stop
        ;;
        *)
            echo "Requirement:"
            echo "1. helm: sudo snap install helm --classic"
            echo "2. Set up sudo without password and run this with normal user"
            echo "----"
            echo "Description:"
            echo "This Script will create a one node Kubernetes will schedulable master. It also inits tiller with helm"
            echo "tested with 16.04 Ubuntu"
            echo "[./createk8s.sh start simple] for minimal setup (no cni plugin, no helm init)"
        ;;
    esac

}
main ${1} ${2}