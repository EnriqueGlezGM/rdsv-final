#!/bin/bash

############################################
# Se parte de la MV ya creada mediante:
#   $HOME/shared/rdsv-final/bin/get-osmlab-k8s
###Ahora dentro de la MV, es necesario crear el tunel y configurar el entorno para acceder a OSM:
###   $HOME/shared/rdsv-final/bin/rdsv-start-tun <letra>
###   $HOME/shared/rdsv-final/bin/rdsv-config-osmlab <letter>
############################################


# Verifica si la variable global $OSMNS está definida
if [ -z "$OSMNS" ]; then
    echo "La variable global \$OSMNS no está definida. Es necesario configurar el entorno de OSM previamente."
    exit 1
fi

# Se instala el nuevo repositorio
cd /tmp
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
mkdir $HOME/helm-files
cd ~/helm-files
helm package $HOME/shared/rdsv-final/helm/accesschart
helm package $HOME/shared/rdsv-final/helm/cpechart
helm package $HOME/shared/rdsv-final/helm/wanchart
helm package $HOME/shared/rdsv-final/helm/ctrlchart
helm package $HOME/shared/rdsv-final/helm/wanchart
MYIP=$( ifconfig | grep 10.11.13 | awk '{print $2}' )
helm repo index --url http://$MYIP/ .
docker run --restart always --name helm-repo -p 80:80 -v ~/helm-files:/usr/share/nginx/html:ro -d nginx
osm repo-add --type helm-chart --description "RoMaEn" sdedge-ns-repo http://$MYIP

#Onboarding e instanciacion de NSs/VNFs
osm vnfd-create $HOME/shared/rdsv-final/pck/accessknf_vnfd
osm vnfd-create $HOME/shared/rdsv-final/pck/cpeknf_vnfd
osm vnfd-create $HOME/shared/rdsv-final/pck/ctrlknf_vnfd
osm vnfd-create $HOME/shared/rdsv-final/pck/wanknf_vnfd
osm nsd-create $HOME/shared/rdsv-final/pck/sdedge_nsd

#Se arranca el escenario
kubectl get -n $OSMNS network-attachment-definitions
cd $HOME/shared/rdsv-final/vnx
sudo vnx -f sdedge_nfv.xml -t

#Se abren todas las consolas del escenario
export NSID1=$(osm ns-create --ns_name sdedge1 --nsd_name sdedge --vim_account dummy_vim)
export NSID2=$(osm ns-create --ns_name sdedge2 --nsd_name sdedge --vim_account dummy_vim)

echo "export NSID1=$NSID1" >> ~/.bashrc
echo "export NSID2=$NSID2" >> ~/.bashrc

#Observaciones de ejecucion
echo 'Para abrir las consulas de la sede uno, esperar a que se inicialice, y luego ejecutar: bin/sdw-knf-consoles open $NSID1'
echo 'Para abrir las consulas de la sede dos, esperar a que se inicialice, y luego ejecutar: bin/sdw-knf-consoles open $NSID2'
firefox http://10.11.13.1/instances/ns &
