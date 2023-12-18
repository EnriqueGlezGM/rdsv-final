# RDSV-Final

En esta práctica, se va a profundizar en las funciones de red virtualizadas (VNF) y su orquestación, aplicadas al caso de un servicio SD-WAN ofrecido por un proveedor de telecomunicaciones. El escenario que se va a utilizar está inspirado en la reconversión de las centrales de proximidad a centros de datos que permiten, entre otras cosas, reemplazar servicios de red ofrecidos mediante hardware específico y propietario por servicios de red definidos por software sobre hardware de propósito general. Las funciones de red que se despliegan en estas centrales se gestionan mediante una plataforma de orquestación como OSM o XOS.

Un caso de virtualización de servicio de red para el que ya existen numerosas propuestas y soluciones es el del servicio vCPE (Virtual Customer Premises Equipment). En nuestro caso, veremos ese servicio vCPE en el contexto del acceso a Internet desde una red corporativa, y lo extenderemos para llevar las funciones de un equipo SD-WAN Edge a la central de proximidad.
Más informacion en [Práctica 4](https://github.com/educaredes/sdedge-ns/blob/main/doc/rdsv-p4.md).

En el caso que se trata, se trata de un ampiación de esta práctica con el objetivo de:
- añadirle soporte de QoS implementado mediante SDN con Ryu
- añadir servicios adicionales

Más información en [recomendaciones](https://github.com/educaredes/sdedge-ns/blob/main/doc/rdsv-final.md).


## Instalación

Al tratarse de un repositorio privado es necesario verificar la identidad antes de clonarlo.
La guia oficial para [generar una nueva clave SSH](https://docs.github.com/es/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key) y [agregar una clave SSH y usarla para la autenticación](https://docs.github.com/es/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account).


## Preparación del entorno
Con las credenciales correctamente configuradas, clonar repositorio y arrancar la MV:
```bash
cd $HOME/shared/GitHub
git clone git@github.com:EnriqueGlezGM/rdsv-final.git
rdsv-final/bin/get-osmlab-k8s

```
**¡ATENCION! El resto de la práctica se realiza sobre la máquina virtual.**

Primero se inicializa el tunel, y luego se configura el entorno para acceder a OSM:
```bash
# Si realiza la práctica desde el laboratorio
cd $HOME/shared/GitHub/rdsv-final
```
```bash
./rdsv-start-tun <letra>
```
```bash
./rdsv-config-osmlab <letra>
```
```bash
# Si realiza la práctica desde el laboratorio
cd $HOME/shared/GitHub/rdsv-final
```
```bash
./rdsv-start-tun labtun5.dit.upm.es <letra>
```
```bash
./rdsv-config-osmlab <letra>
```
A continuación, cierre el terminal y abra uno nuevo.

En el nuevo terminal, obtenga los valores asignados a las diferentes variables configuradas para acceder a OSM (OSM_*) y el identificador del namespace de K8S creado para OSM (OSMNS):
```bash
echo "-- OSM_USER=$OSM_USER"
echo "-- OSM_PASSWORD=$OSM_PASSWORD"
echo "-- OSM_PROJECT=$OSM_PROJECT"
echo "-- OSM_HOSTNAME=$OSM_HOSTNAME"
echo "-- OSMNS=$OSMNS"

```

## Arranque
En la terminal que se acaba de abrir con als variables globales accesibles, se ejecuta el script de inicialización:
```bash
$HOME/shared/GitHub/rdsv-final/start.sh

```

## Posibles problemas de ejecución
Que los enlaces ya estan creados, para ello es necesario elimiarlos mediante:
```bash
ovs-vsctl list-br
ovs-vsctl del-br MplsWan
ovs-vsctl del-br AccessNet1
ovs-vsctl del-br AccessNet2
ovs-vsctl del-br ExtNet1
ovs-vsctl del-br ExtNet2
ovs-vsctl list-br

```

Que las KNFs/NSs ya estan en ejecución. Para eso acceder a [OSM](http://10.11.13.1/) y eliminar las instancias de las NSs.
