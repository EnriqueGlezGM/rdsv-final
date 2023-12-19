#!/bin/bash

export KUBECTL="microk8s kubectl"

echo "** Inicializando variables **"
sleep 1
accesschart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep accesschart)
cpechart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart)
wanchart=$($KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart)

cpesdedge1=$(echo "$cpechart" | head -n 1)
accsdedge1=$(echo "$accesschart" | head -n 1)
wansdedge1=$(echo "$wanchart" | head -n 1)
# export test=`kubectl -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart`
# export wansdedge1=`$KUBECTL -n $OSMNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart | head -n 1`

echo "Access chart: $accsdedge1"
sleep 1
echo "CPE chart: $cpesdedge1"
sleep 1
echo "WAN chart: $wansdedge1"
sleep 1

echo "** Limpiando y configurando INTERFACES **"
$KUBECTL -n $OSMNS exec $accsdedge1 -- sed -i '/^INTERFACES=/d' /etc/default/arpwatch
sleep 1
$KUBECTL -n $OSMNS exec $accsdedge1 -- sh -c 'echo "INTERFACES=\"net1\"" >> /etc/default/arpwatch'

$KUBECTL -n $OSMNS exec $cpesdedge1 -- sed -i '/^INTERFACES=/d' /etc/default/arpwatch
sleep 1
$KUBECTL -n $OSMNS exec $cpesdedge1 -- sh -c 'echo "INTERFACES=\"brint\"" >> /etc/default/arpwatch'

echo "** Borrando cache **"
if $KUBECTL -n $OSMNS exec $accsdedge1 -- test -f /var/lib/arpwatch/net1.dat 2>/dev/null; then
    $KUBECTL -n $OSMNS exec $accsdedge1 -- rm -f /var/lib/arpwatch/net1.dat
    echo "Eliminando net1.dat en KNF Access"
fi

if $KUBECTL -n $OSMNS exec $cpesdedge1 -- test -f /var/lib/arpwatch/brint.dat 2>/dev/null; then
    $KUBECTL -n $OSMNS exec $cpesdedge1 -- rm -f /var/lib/arpwatch/brint.dat
    echo "Eliminando brint.dat en KNF CPE"

fi

if $KUBECTL -n $OSMNS exec $wansdedge1 -- test -f /var/lib/arpwatch/arp.dat 2>/dev/null; then
    $KUBECTL -n $OSMNS exec $wansdedge1 -- rm -f /var/lib/arpwatch/arp.dat
    echo "Eliminando arp.dat en KNF WAN"

fi

echo "** Arrancando servicio arpwatch **"
sleep 2
$KUBECTL -n $OSMNS exec $accsdedge1 -- service arpwatch start
sleep 2
$KUBECTL -n $OSMNS exec $cpesdedge1 -- service arpwatch start
sleep 2
$KUBECTL -n $OSMNS exec $wansdedge1 -- service arpwatch start
sleep 2
echo "** Servicio arpwatch arrancado correctamente en Net1 **"

# kubectl -n $OSMNS exec -it $accsdedge1 -- touch /tmp/arp.dat
# kubectl -n $OSMNS exec -it $accsdedge1 -- touch /var/lib/arpwatch/arp.dat
# kubectl -n $OSMNS exec -it $accsdedge1 -- arpwatch -d -i net1 -f /tmp/arp.dat




