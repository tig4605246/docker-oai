#!/bin/bash

   APISERVER=`kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'`
   TOKEN=`kubectl get secret $(kubectl get serviceaccount default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode `
   

apply_cr(){
   curl \
      -H "content-Type: application/json" \
      -H "Authorization: Bearer ${TOKEN}"\
      --insecure \
      -X POST ${APISERVER}/apis/mosaic5g.com/v1alpha1/namespaces/default/mosaic5gs \
      -d '{"apiVersion":"mosaic5g.com/v1alpha1","kind":"Mosaic5g","metadata":{"name":"mosaic5g"},"spec":{"size":1,"cnImage":"mosaic5gecosys/oaicn:1.1","ranImage":"mosaic5gecosys/oairan:1.1","mcc":"208","mnc":"95","eutraBand":"7","downlinkFrequency":"2685000000L","uplinkFrequencyOffset":"-120000000","configurationPathofCN":"/var/snap/oai-cn/current/","configurationPathofRAN":"/var/snap/oai-ran/current/","snapBinaryPath":"/snap/bin/","hssDomainName":"oaicn","mmeDomainName":"oaicn","spgwDomainName":"oaicn","mysqlDomainName":"mysql","dns":"192.168.106.12","flexRAN":false,"flexRANDomainName":"flexran"}}'

}

delete_cr(){
   curl \
      -H "content-Type: application/json" \
      -H "Authorization: Bearer ${TOKEN}"\
      --insecure \
      -X DELETE ${APISERVER}/apis/mosaic5g.com/v1alpha1/namespaces/default/mosaic5gs/mosaic5g
}

patch_cr(){
   curl \
      -H "content-Type: application/json-patch+json" \
      -H "Authorization: Bearer ${TOKEN}"\
      --insecure \
      -X PATCH ${APISERVER}/apis/mosaic5g.com/v1alpha1/namespaces/default/mosaic5gs/mosaic5g \
      -d '[{"op":"replace","path":"/spec/flexRANDomainName","value":"flexfan"}]'
}

main(){
   echo "---main start---"
   case ${1} in
      apply_cr)
         apply_cr
      ;;
      delete_cr)
         delete_cr
      ;;
      patch_cr)
         patch_cr
      ;;
   esac
   
   echo "---main end---"
}

main ${1}