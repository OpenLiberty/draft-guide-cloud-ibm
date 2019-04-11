

#!/bin/bash

##############################################################################
##
##  Travis CI test script
##
##############################################################################

printf "\nmvn -q package\n"
mvn -q package

printf "\nhelm init\n"
helm init

printf "\nhelm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/\n"
helm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/

printf "\nhelm install ... name-app\n"
helm install --name name-app \
    --set image.repository=name \
    --set image.tag=1.0-SNAPSHOT \
    --set service.port=9080 \
    --set service.targetPort=9080 \
    --set ssl.enabled=false \
    ibm-charts/ibm-open-liberty 

printf "\nhelm install ... ping-app\n"
helm install --name ping-app \
    --set image.repository=ping \
    --set image.tag=1.0-SNAPSHOT \
    --set service.port=9080 \
    --set service.targetPort=9080 \
    --set ssl.enabled=false \
    ibm-charts/ibm-open-liberty


printf "\nsleep 120\n"
sleep 120

printf "\nkubectl get pods\n"
kubectl get pods

GUIDE_IP=`minikube ip`
GUIDE_NAME_PORT=`kubectl get service name-app-ibm-open-libert -o jsonpath="{.spec.ports[0].nodePort}"`
GUIDE_PING_PORT=`kubectl get service ping-app-ibm-open-libert -o jsonpath="{.spec.ports[0].nodePort}"`

printf "\nMinikube IP: $GUIDE_IP\n"
printf "\nName Port: $GUIDE_NAME_PORT\n"
printf "\nPing Port: $GUIDE_PING_PORT\n"

printf "\ncurl http://$GUIDE_IP:$GUIDE_NAME_PORT/api/name\n"
curl http://$GUIDE_IP:$GUIDE_NAME_PORT/api/name

printf "\ncurl http://$GUIDE_IP:$GUIDE_PING_PORT/api/ping/name-service\n"
curl http://$GUIDE_IP:$GUIDE_PING_PORT/api/ping/name-app-ibm-open-libert

printf "\nmvn verify -Ddockerfile.skip=true -Dcluster.ip=[ip-address] -Dname.node.port=[name-node-port] -Dping.node.port=[ping-node-port] -Dname.kube.service=name-app-ibm-open-libert\n"
mvn verify -Ddockerfile.skip=true -Dcluster.ip=$GUIDE_IP -Dname.node.port=$GUIDE_NAME_PORT -Dping.node.port=$GUIDE_PING_PORT -Dname.kube.service=name-app-ibm-open-libert


printf "\nkubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep name)\n"
kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep name)

printf "\nkubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep ping)\n" 
kubectl logs $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep ping)
