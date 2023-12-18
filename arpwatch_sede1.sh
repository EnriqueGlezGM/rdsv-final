#!/bin/bash

export KUBECTL="microk8s kubectl"

echo "** Inicializando variables **"
accesschart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep accesschart)
cpechart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart)
wanchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart)

cpesdedge1=$(echo "$cpechart" | head -n 1)
accsdedge1=$(echo "$accesschart" | head -n 1)
wansdedge1=$(echo "$wanchart" | head -n 1)

echo "Access chart: $accsdedge1"
sleep 1
echo "CPE chart: $cpesdedge1"
sleep 1
echo "WAN chart: $wansdedge1"
sleep 1

echo "** Parando el servicio arpwatch **"
$KUBECTL -n $OSMNS exec -it $accsdedge1 -- pkill arpwatch
$KUBECTL -n $OSMNS exec -it $cpesdedge1 -- pkill arpwatch
$KUBECTL -n $OSMNS exec -it $wansdedge1 -- pkill arpwatch
sleep 4
echo "** Servicio arpwatch finalizado correctamente **"
sleep 1
echo -e "\nCargando contenido de net1.dat..."
sleep 2
echo -e "\n ## Captura de trafico KNF Access: ##"
$KUBECTL -n $OSMNS exec -it $accsdedge1 -- cat /var/lib/arpwatch/net1.dat
echo -e "\n ## Captura de trafico KNF CPE: ##"
$KUBECTL -n $OSMNS exec -it $cpesdedge1 -- cat /var/lib/arpwatch/net1.dat

echo -e "\nCargando contenido de brint.dat..."
sleep 2
echo -e "\n ## Captura de trafico KNF CPE: ##"
$KUBECTL -n $OSMNS exec -it $cpesdedge1 -- cat /var/lib/arpwatch/brint.dat

echo -e "\nCargando contenido de arp.dat..."
sleep 2
echo -e "\n ## Captura de trafico KNF WAN: ##"
$KUBECTL -n $OSMNS exec -it $wansdedge1 -- cat /var/lib/arpwatch/arp.dat

