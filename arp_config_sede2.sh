#!/bin/bash

export KUBECTL="microk8s kubectl"

echo "** Inicializando variables **"
sleep 1
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

echo "** Limpiando y configurando INTERFACES **"
$KUBECTL -n $OSMNS exec $accsdedge2 -- sed -i '/^INTERFACES=/d' /etc/default/arpwatch
sleep 1
$KUBECTL -n $OSMNS exec $accsdedge2 -- sh -c 'echo "INTERFACES=\"net2\"" >> /etc/default/arpwatch'

$KUBECTL -n $OSMNS exec $cpesdedge2 -- sed -i '/^INTERFACES=/d' /etc/default/arpwatch
sleep 1
$KUBECTL -n $OSMNS exec $cpesdedge2 -- sh -c 'echo "INTERFACES=\"brint\"" >> /etc/default/arpwatch'

echo "** Borrando cache **"
if $KUBECTL -n $OSMNS exec $accsdedge2 -- test -f /var/lib/arpwatch/net2.dat 2>/dev/null; then
    $KUBECTL -n $OSMNS exec $accsdedge2 -- rm -f /var/lib/arpwatch/net2.dat
    echo "Eliminando net2.dat en KNF Access"
fi

if $KUBECTL -n $OSMNS exec $cpesdedge2 -- test -f /var/lib/arpwatch/brint.dat 2>/dev/null; then
    $KUBECTL -n $OSMNS exec $cpesdedge2 -- rm -f /var/lib/arpwatch/brint.dat
    echo "Eliminando brint.dat en KNF CPE"

fi

if $KUBECTL -n $OSMNS exec $wansdedge2 -- test -f /var/lib/arpwatch/arp.dat 2>/dev/null; then
    $KUBECTL -n $OSMNS exec $wansdedge2 -- rm -f /var/lib/arpwatch/arp.dat
    echo "Eliminando arp.dat en KNF WAN"

fi

echo "** Arrancando servicio arpwatch **"
sleep 2
$KUBECTL -n $OSMNS exec $accsdedge2 -- service arpwatch start
sleep 2
$KUBECTL -n $OSMNS exec $cpesdedge2 -- service arpwatch start
sleep 2
$KUBECTL -n $OSMNS exec $wansdedge2 -- service arpwatch start
sleep 2
echo "** Servicio arpwatch arrancado correctamente en Net2 **"

# kubectl -n $OSMNS exec -it $accsdedge2 -- touch /tmp/arp.dat
# kubectl -n $OSMNS exec -it $accsdedge2 -- touch /var/lib/arpwatch/arp.dat
# kubectl -n $OSMNS exec -it $accsdedge2 -- arpwatch -d -i net2 -f /tmp/arp.dat




