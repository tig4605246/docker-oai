#!/bin/bash

kubectl apply -f oai-cn/oaicn.yaml  
sleep 15
kubectl apply -f oai-ran/oairan.yaml