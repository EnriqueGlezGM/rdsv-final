#!/bin/bash

export KUBECTL="microk8s kubectl"
#export OSMNS=12c22b8c-eab4-401d-a171-c978c6effc82

echo "** Inicializando variables **"
accesschart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep accesschart)
cpechart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart)
wanchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart)
ctrlchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep ctrlchart)

accsdedge2=$(echo "$accesschart" | sed -n 2p)
cpesdedge2=$(echo "$cpechart" | sed -n 2p)
wansdedge2=$(echo "$wanchart" | sed -n 2p)
ctrlsdedge2=$(echo "$ctrlchart" | sed -n 2p)

echo "Access chart: $accsdedge2"
sleep 1
echo "CPE chart: $cpesdedge2"
sleep 1
echo "WAN chart: $wansdedge2"
sleep 1
echo "CTRL chart: $ctrlsdedge2"
sleep 1


echo "** Obteniendo IP CTRL **"
sleep 2
deployment_id() {
    echo `osm ns-show $1 | grep kdu-instance | grep $2 | awk -F':' '{gsub(/[", |]/, "", $2); print $2}' `
}

SIID="$NSID2"
OSMCTR=$(deployment_id $SIID "ctrl")
VCTR="deploy/$OSMCTR"
if [[ ! $VCTR =~ "sdedge-ns-repo-ctrlchart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <ctrl_deployment_id>: $VCTR"
    exit 1
fi

CTR_EXEC="$KUBECTL exec -n $OSMNS $VCTR --"
IPCTR=`$CTR_EXEC hostname -I | awk '{print $1}'`
echo "IPCTR = $IPCTR"

echo "** Obteniendo puerto controlador **"
sleep 2
CTR_SERV="${VCTR/deploy\//}"
PORTCTR=`$KUBECTL get -n $OSMNS -o jsonpath="{.spec.ports[0].nodePort}" service $CTR_SERV`
echo "PORTCTR = $PORTCTR"

echo "Configurando OpenFlowVS en KNF Access..."
sleep 1
$KUBECTL -n $OSMNS exec -i $accsdedge2 -- ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$KUBECTL -n $OSMNS exec -i $accsdedge2 -- ovs-vsctl set-fail-mode brwan secure
$KUBECTL -n $OSMNS exec -i $accsdedge2 -- ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000002
$KUBECTL -n $OSMNS exec -i $accsdedge2 -- ovs-vsctl set-controller brwan tcp:$IPCTR:6633
$KUBECTL -n $OSMNS exec -i $accsdedge2 -- ovs-vsctl set-manager ptcp:6632

echo "Configurando OpenFlowVS en KNF CPE..."
sleep 1
$KUBECTL -n $OSMNS exec -i $cpesdedge2 -- ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$KUBECTL -n $OSMNS exec -i $cpesdedge2 -- ovs-vsctl set-fail-mode brwan secure
$KUBECTL -n $OSMNS exec -i $cpesdedge2 -- ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000003
$KUBECTL -n $OSMNS exec -i $cpesdedge2 -- ovs-vsctl set-controller brwan tcp:$IPCTR:6633
$KUBECTL -n $OSMNS exec -i $cpesdedge2 -- ovs-vsctl set-manager ptcp:6632

echo "OpenflowVS configurado"
sleep 1
echo "Aplicando las reglas de la sdwan con ryu"
sleep 2
RYU_ADD_URL="http://localhost:$PORTCTR/stats/flowentry/add"
echo "URL: $RYU_ADD_URL"
curl -X POST -d @json/from-wan-to-access.json $RYU_ADD_URL
curl -X POST -d @json/to-wan-from-access.json $RYU_ADD_URL
curl -X POST -d @json/from-wan-to-cpe.json $RYU_ADD_URL
curl -X POST -d @json/to-wan-from-cpe.json $RYU_ADD_URL
curl -X POST -d @json/broadcast-from-cpe.json $RYU_ADD_URL

