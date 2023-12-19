#!/bin/bash

export KUBECTL="microk8s kubectl"

echo "** Inicializando variables **"
accesschart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep accesschart)
cpechart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart)
wanchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart)

cpesdedge2=$(echo "$cpechart" | sed -n 2p)
accsdedge2=$(echo "$accesschart" | sed -n 2p)
wansdedge2=$(echo "$wanchart" | sed -n 2p)

echo "Access chart: $accsdedge2"
sleep 1
echo "CPE chart: $cpesdedge2"
sleep 1
echo "WAN chart: $wansdedge2"
sleep 1

echo "** Parando el servicio arpwatch **"
$KUBECTL -n $OSMNS exec -it $accsdedge2 -- pkill arpwatch
$KUBECTL -n $OSMNS exec -it $cpesdedge2 -- pkill arpwatch
$KUBECTL -n $OSMNS exec -it $wansdedge2 -- pkill arpwatch
sleep 4
echo "** Servicio arpwatch finalizado correctamente **"
sleep 1
echo -e "\nCargando contenido de net2.dat..."
sleep 2
echo -e "\n ## Captura de trafico KNF Access: ##"
$KUBECTL -n $OSMNS exec -it $accsdedge2 -- cat /var/lib/arpwatch/net2.dat

echo -e "\nCargando contenido de brint.dat..."
sleep 2
echo -e "\n ## Captura de trafico KNF CPE: ##"
$KUBECTL -n $OSMNS exec -it $cpesdedge2 -- cat /var/lib/arpwatch/brint.dat

