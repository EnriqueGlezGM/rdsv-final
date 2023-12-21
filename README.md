# RDSV-Final

En esta práctica, se va a profundizar en las funciones de red virtualizadas (VNF) y su orquestación, aplicadas al caso de un servicio SD-WAN ofrecido por un proveedor de telecomunicaciones. El escenario que se va a utilizar está inspirado en la reconversión de las centrales de proximidad a centros de datos que permiten, entre otras cosas, reemplazar servicios de red ofrecidos mediante hardware específico y propietario por servicios de red definidos por software sobre hardware de propósito general. Las funciones de red que se despliegan en estas centrales se gestionan mediante una plataforma de orquestación como OSM o XOS.

Un caso de virtualización de servicio de red para el que ya existen numerosas propuestas y soluciones es el del servicio vCPE (Virtual Customer Premises Equipment). En nuestro caso, veremos ese servicio vCPE en el contexto del acceso a Internet desde una red corporativa, y lo extenderemos para llevar las funciones de un equipo SD-WAN Edge a la central de proximidad.
Más informacion en [Práctica 4](https://github.com/educaredes/sdedge-ns/blob/main/doc/rdsv-p4.md).

En el caso que se trata, se trata de un ampliación de esta práctica con el objetivo de:
- añadirle soporte de QoS implementado mediante SDN con Ryu
- añadir servicios adicionales

Más información en [recomendaciones](https://github.com/educaredes/sdedge-ns/blob/main/doc/rdsv-final.md).


## Instalación (SOLO SI ES UN REPOSITORIO PRIVADO)

Al tratarse de un repositorio privado es necesario verificar la identidad. Solo es necesario hacerlo una unica vez.
La guia oficial para [generar una nueva clave SSH](https://docs.github.com/es/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key) y [agregar una clave SSH y usarla para la autenticación](https://docs.github.com/es/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account).


## Preparación del entorno
Con las credenciales correctamente configuradas, clonar repositorio y arrancar la MV:
```bash
cd $HOME/shared
git clone git@github.com:EnriqueGlezGM/rdsv-final.git
rdsv-final/bin/get-osmlab-k8s
echo 'Los siguientes comandos en la MV'

```
**¡ATENCION! El resto de la práctica se realiza sobre la máquina virtual.**

Primero se inicializa el tunel, y luego se configura el entorno para acceder a OSM:
```bash
# Si realiza la práctica desde el laboratorio y usas la letra U
cd $HOME/shared/rdsv-final/bin
./rdsv-start-tun U
./rdsv-config-osmlab U
echo 'Cierre el terminal actual'
```


A continuación, cierre el terminal anterior, y ejecuta los comandos ahora en el que se acaba de abrir.

En el nuevo terminal, obtenga los valores asignados a las diferentes variables configuradas para acceder a OSM (OSM_*) y el identificador del namespace de K8S creado para OSM (OSMNS):
```bash
echo "-- OSM_USER=$OSM_USER"
echo "-- OSM_PASSWORD=$OSM_PASSWORD"
echo "-- OSM_PROJECT=$OSM_PROJECT"
echo "-- OSM_HOSTNAME=$OSM_HOSTNAME"
echo "-- OSMNS=$OSMNS"

```

## Arranque
En la terminal que se acaba de abrir con las variables globales accesibles, se ejecuta el script de inicialización:
```bash
$HOME/shared/rdsv-final/start.sh

```

## Configurar sedes
Se abrira de nuevo otra terminal donde es necesario ejecutar lo siguiente para configurar las sedes:
```bash
cd $HOME/shared/rdsv-final
$HOME/shared/rdsv-final/sdedge1.sh
$HOME/shared/rdsv-final/sdedge2.sh
$HOME/shared/rdsv-final/bin/sdw-knf-consoles open $NSID1
$HOME/shared/rdsv-final/bin/sdw-knf-consoles open $NSID2

```

## Orden de ejecución - Escenario 1: Switches brwan Flowmanager [sin QoS]
Se indica el orden de ejecución de los scripts:
```bash
cd $HOME/shared/rdsv-final
$HOME/shared/rdsv-final/sdwan1.sh
$HOME/shared/rdsv-final/sdwan2.sh
$HOME/shared/rdsv-final/brwan_config_sede1.sh
$HOME/shared/rdsv-final/brwan_config_sede2.sh

```

## Orden de ejecución - Escenario 2: Switches brwan QoS Simple Switch [con QoS]
Se indica el orden de ejecución de los scripts. Se parte del escenario anterior, aunque existe la opción de unicamente ejecutar este escenario haciendo uso de start sdwan qos.
```bash
cd $HOME/shared/rdsv-final
$HOME/shared/rdsv-final/killer.sh
$HOME/shared/rdsv-final/qos_brwan_config_sede1.sh
$HOME/shared/rdsv-final/qos_brwan_config_sede2.sh
$HOME/shared/rdsv-final/qos_sede1.sh
$HOME/shared/rdsv-final/qos_sede2.sh

```

## Posibles problemas de ejecución
Que los enlaces ya estan creados, para ello es necesario elimiarlos mediante:
```bash
sudo ovs-vsctl list-br
sudo ovs-vsctl del-br MplsWan
sudo ovs-vsctl del-br AccessNet1
sudo ovs-vsctl del-br AccessNet2
sudo ovs-vsctl del-br ExtNet1
sudo ovs-vsctl del-br ExtNet2
sudo ovs-vsctl list-br

```

Que las KNFs/NSs ya estan en ejecución. Para eso acceder a [OSM](http://10.11.13.1/) y eliminar las instancias de las NSs.
