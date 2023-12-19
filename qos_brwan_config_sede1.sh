#!/bin/bash

export KUBECTL="microk8s kubectl"
#export OSMNS=12c22b8c-eab4-401d-a171-c978c6effc82

echo "** Inicializando variables **"
accesschart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep accesschart)
cpechart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart)
wanchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart)
ctrlchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep ctrlchart)

accsdedge1=$(echo "$accesschart" | head -n 1)
cpesdedge1=$(echo "$cpechart" | head -n 1)
wansdedge1=$(echo "$wanchart" | head -n 1)
ctrlsdedge1=$(echo "$ctrlchart" | head -n 1)

echo "Access chart: $accsdedge1"
sleep 1
echo "CPE chart: $cpesdedge1"
sleep 1
echo "WAN chart: $wansdedge1"
sleep 1
echo "CTRL chart: $ctrlsdedge1"
sleep 1


echo "** Obteniendo IP CTRL **"
sleep 2
deployment_id() {
    echo `osm ns-show $1 | grep kdu-instance | grep $2 | awk -F':' '{gsub(/[", |]/, "", $2); print $2}' `
}

SIID="$NSID1"
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
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set-fail-mode brwan secure
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000002
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set-controller brwan tcp:$IPCTR:6633
$KUBECTL -n $OSMNS exec -i $accsdedge1 -- ovs-vsctl set-manager ptcp:6632

echo "Configurando OpenFlowVS en KNF CPE..."
sleep 1
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set-fail-mode brwan secure
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000003
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set-controller brwan tcp:$IPCTR:6633
$KUBECTL -n $OSMNS exec -i $cpesdedge1 -- ovs-vsctl set-manager ptcp:6632

echo "OpenflowVS QoS configurado"







