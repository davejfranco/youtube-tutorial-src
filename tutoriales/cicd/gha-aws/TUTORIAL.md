# Desplegar una aplicacion desde GitHub Actions a AWS EKS

En este tutorial vamos a desplegar una aplicación en AWS EKS usando GitHub Actions. Para ello, vamos a crear un cluster de Kubernetes en AWS EKS y desplegar una aplicación de ejemplo. 


## pre-requisitos
- Tener una cuenta en GitHub
- Tener una cuenta en AWS
- Tener instalado [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Tener instalado [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Tener instalado [aws-cli](https://docs.aws.amazon.com/es_es/cli/latest/userguide/getting-started-install.html)


El código para la infraestructura lo puedes encontrar en este mismo proyecto en la carpeta `tutoriales/terraform/eks`. El proyecto de la aplicación de ejemplo lo puedes encontrar en entre mis repositorios de GitHub [aquí](https://github.com/davejfranco/python-fastapi-demo)

## Crear el cluster de Kubernetes en AWS EKS

Para crear el cluster de Kubernetes en AWS EKS, vamos a utilizar Terraform. Nos movemos al directorio `tutoriales/terraform/eks` y ejecutamos el siguiente comando:
```bash
terraform init
terraform apply \ 
  -var="cluster_name=mi_cluster" \ 
  --auto-approve
```

Nota: Puedes cambiar las variables del modulo de eks para crear el cluster en la región que quieras, con el nombre que quieras y el resto de caracteristicas que prefieras.

Esto nos creará la vpc y el cluster de Kubernetes en AWS EKS. Una vez finalizado el proceso, nos mostrará la configuración para conectarnos al cluster de Kubernetes. Para conectarnos al cluster de Kubernetes, ejecutamos el siguiente comando:

```bash
aws eks update-kubeconfig \
  --name [cluster_name] \
  --alias [cluster_name] \
  --region us-east-1
```

Una vez conectados al cluster de Kubernetes, podemos comprobar que el cluster está funcionando correctamente ejecutando el siguiente comando:

```bash
kubectl get nodes
```

## Crear CI/CD con GitHub Actions

Puedes copiar el código de la aplicación de ejemplo de mi repositorio de GitHub [aquí](github.com/davejfranco/python-fastapi-demo).





