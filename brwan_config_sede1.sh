#!/bin/bash

export KUBECTL="microk8s kubectl"
#export OSMNS=12c22b8c-eab4-401d-a171-c978c6effc82

echo "** Inicializando variables **"
accesschart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep accesschart)
cpechart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart)
wanchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart)

accsdedge1=$(echo "$accesschart" | head -n 1)
cpesdedge1=$(echo "$cpechart" | head -n 1)
wansdedge1=$(echo "$wanchart" | head -n 1)

echo "Access chart: $accsdedge1"
sleep 1
echo "CPE chart: $cpesdedge1"
sleep 1
echo "WAN chart: $wansdedge1"
sleep 1


echo "** Obteniendo IP WAN **"
sleep 2
deployment_id() {
    echo `osm ns-show $1 | grep kdu-instance | grep $2 | awk -F':' '{gsub(/[", |]/, "", $2); print $2}' `
}

SIID="$NSID1"
OSMWAN=$(deployment_id $SIID "wan")
VWAN="deploy/$OSMWAN"
if [[ ! $VWAN =~ "sdedge-ns-repo-wanchart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <wan_deployment_id>: $VWAN"
    exit 1
fi

WAN_EXEC="$KUBECTL exec -n $OSMNS $VWAN --"
IPWAN=`$WAN_EXEC hostname -I | awk '{print $1}'`
echo "IPWAN = $IPWAN"

echo "** Obteniendo puerto controlador **"
sleep 2
WAN_SERV="${VWAN/deploy\//}"
PORTWAN=`$KUBECTL get -n $OSMNS -o jsonpath="{.spec.ports[0].nodePort}" service $WAN_SERV`
echo "PORTWAN = $PORTWAN"

echo "Configurando OpenFlowVS en KNF Access..."
sleep 1
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set-fail-mode brwan secure
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000002
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set-controller brwan tcp:$IPWAN:6633
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set-manager ptcp:6632

echo "Configurando OpenFlowVS en KNF CPE..."
sleep 1
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set-fail-mode brwan secure
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000003
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set-controller brwan tcp:$IPWAN:6633
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set-manager ptcp:6632

echo "OpenflowVS configurado"
sleep 1
echo "Aplicando las reglas de la sdwan con ryu"
sleep 2
RYU_ADD_URL="http://localhost:$PORTWAN/stats/flowentry/add"
echo "URL: $RYU_ADD_URL"
curl -X POST -d @json/from-wan-to-access.json $RYU_ADD_URL
curl -X POST -d @json/to-wan-from-access.json $RYU_ADD_URL
curl -X POST -d @json/from-wan-to-cpe.json $RYU_ADD_URL
curl -X POST -d @json/to-wan-from-cpe.json $RYU_ADD_URL
curl -X POST -d @json/broadcast-from-cpe.json $RYU_ADD_URL

