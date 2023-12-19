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

echo "** Obteniendo IP CTRL e IP WAN **"
sleep 2
deployment_id() {
    echo `osm ns-show $1 | grep kdu-instance | grep $2 | awk -F':' '{gsub(/[", |]/, "", $2); print $2}' `
}

SIID="$NSID1"
OSMCTR=$(deployment_id $SIID "ctrl")
OSMWAN=$(deployment_id $SIID "wan")
VCTR="deploy/$OSMCTR"
VWAN="deploy/$OSMWAN"
if [[ ! $VCTR =~ "sdedge-ns-repo-ctrlchart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <ctrl_deployment_id>: $VCTR"
    exit 1
fi

if [[ ! $VWAN =~ "sdedge-ns-repo-wanchart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <wan_deployment_id>: $VWAN"
    exit 1
fi

CTR_EXEC="$KUBECTL exec -n $OSMNS $VCTR --"
WAN_EXEC="$KUBECTL exec -n $OSMNS $VWAN --"
IPCTR=`$CTR_EXEC hostname -I | awk '{print $1}'`
echo "IPCTR = $IPCTR"

IPWAN=`$WAN_EXEC hostname -I | awk '{print $1}'`
echo "IPWAN = $IPWAN"


echo "Configurando calidad de servicio..."
sleep 1

TCP="tcp:$IPWAN:6632"

$KUBECTL -n $OSMNS exec -i $wansdedge1 -- curl -X PUT -d "$TCP" http://$IPCTR:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr

$KUBECTL -n $OSMNS exec -i $ctrlsdedge1 -- curl -X POST -d '{"port_name": "axswan", "type": "linux-htb", "max_rate": "2400000", "queues": [{"min_rate": "800000"}]}' http://127.0.0.1:8080/qos/queue/0000000000000001
$KUBECTL -n $OSMNS exec -i $ctrlsdedge1 -- curl -X POST -d '{"match": {"nw_dst": "10.20.1.2", "nw_proto": "UDP", "udp_dst": "5005"}, "actions":{"queue": "0"}}' http://127.0.0.1:8080/qos/rules/0000000000000001
$KUBECTL -n $OSMNS exec -i $ctrlsdedge1 -- curl -X POST -d '{"match": {"nw_dst": "10.20.1.200", "nw_proto": "UDP", "udp_dst": "5005"}, "actions":{"queue": "0"}}' http://127.0.0.1:8080/qos/rules/0000000000000001
$KUBECTL -n $OSMNS exec -i $ctrlsdedge1 -- curl -X GET http://127.0.0.1:8080/qos/rules/0000000000000001

