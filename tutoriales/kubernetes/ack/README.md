# DEMOS ACK - Amazon Controller for Kubernetes

## ¿Qué es ACK?

Es un conjunto de CRDs que se instalan en tu cluster y te permiten controlar recursos de AWS desde tu cluster. Es muy parecido al proyecto Crossplane pero exclusivo para Amazon Web Services.

## Requisitos
- Cuenta de AWS
- aws-cli
- eksctl

## DEMO

### Creación del cluster

En el archivo `cluster.yaml` esta una configuración ejemplo para crear un cluster, los parametros de VPCID y SubnetIDs debes ajustar los a los tuyos. Una vez hecho esto puedes crear tu cluster de la siguiente forma:

```shell
eksctl create cluster -f cluster.yaml
```

### Crear permisos

Para que ACK pueda funcionar necesitamos crear IAM Roles que tengan una trust policy con un proveedor OIDC de tu cluster y las politicas necesarias para permitirle crear los recursos. En este repo hay un script que te permite hacer todo esto sin tener que memorizar los comandos.

Para crear el proveedor de OIDC
```shell
./ack.sh add-oidc <cluster-name> <region>  
```

Una vez creado el proveedor podemos crear el IAM Role por cada ACK Controller

```shell
./ack.sh add-iam-role <cluster-name> <service>
```
Ejemplo:

```shell
./ack.sh add-iam-role ack-demo ec2
```

### Instalar ACK controller 

Una vez tenemos el proveedor y el IAM role instalado procedemos a instalar el controlador

```shell
./ack.sh install-controller <service> <region>
```
Ejemplo:
```shell
./ack.sh install-controller ec2 us-east-1
```
Y listo! ya podemos crear recursos usando ACK. Para instalar controlladores adiciones solo repetir la creación del IAM Role y la instalación del servicio


