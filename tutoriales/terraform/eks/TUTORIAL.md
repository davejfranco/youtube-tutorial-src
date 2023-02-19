# Cluster Kubernetes AWS EKS con Terraform

En este tutorial vamos a crear un cluster de Kubernetes en AWS con Terraform. Puedes ver el video del tutorial [aquí](https://www.youtube.com/watch?v=wF31kva8wPk&ab_channel=DaveOps)

## ¿Que es Terraform?

Terraform es una herramienta de infraestructura como código (IaC) que permite definir y provisionar infraestructura de forma segura y eficiente. Es una herramienta de código abierto escrita en Go y parte de las soluciones de HashiCorp.

## Instalación

Para Instalar Terraform puedes consultar la documentación oficial de Terraform [aquí](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## Pre-requisitos

- Tener una cuenta de AWS con acceso
- Tener instalado aws-cli
- Tener instalado kubectl

## Configuración de terraform para acceder a AWS

Vamos a crear un archivo que llamaremos ``terraform.tf`` y vamos añadir las siguientes líneas:

```hcl
terraform {
  # Minimum required version
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      source = "registry.terraform.io/hashicorp/aws"
    }
  }
}
```
La sección ``required_version`` indica la versión mínima de Terraform que se necesita para ejecutar el código. La sección ``required_providers`` indica que vamos a necesitar el proveedor de AWS para poder crear los recursos de AWS.

Ahora vamos a crear un archivo llamado ``provider.tf`` y vamos a añadir las siguientes líneas:

```hcl
provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "personal"
}
```
Acá indicamos que vamos a usar el proveedor de AWS, la región donde vamos a crear los recursos, el archivo de configuración y el archivo de credenciales de AWS y el perfil que vamos a usar. En mi caso tengo multiples profiles en mi caso añadí el profile personal pero si solo tienes una cuenta de aws configurada puedes omitir la sección profile.

## Creación de la red

Vamos a crear una red para nuestro cluster de Kubernetes. Para ello vamos a crear un archivo llamado ``network.tf`` y vamos a añadir las siguientes líneas:

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "youtube-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  create_igw         = true
  single_nat_gateway = true
  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```
La sección ``source`` nos indica de donde estamos tomando este modulo y usaremos el oficial de AWS para crear nuestra red. Más detalles sobre este modulo lo puedes encontrar [aquí](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

EL uso de modulos nos abstrae de la complejidad de crear recursos de AWS y nos permite crear recursos de forma rápida y sencilla.

Indicaremos el numbre de nuestra red, CIDR de nuestra VPC, las zonas de disponibilidad donde vamos a crear los recursos, las subredes privadas y públicas, si vamos a crear un internet gateway, si vamos a crear un nat gateway y los tags que vamos a añadir a los recursos.

## Creación del cluster de Kubernetes

Vamos a crear un archivo llamado ``eks.tf`` y vamos a añadir las siguientes líneas:

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "youtube-eks"
  cluster_version = "1.24"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets


  eks_managed_node_groups = {
    public = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = data.aws_iam_user.me.arn
      username = "daveops"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Environment = "tutorial"
    Terraform   = "true"
  }
}
```
Al igual que en el caso anterior, la sección ``source`` nos indica de donde estamos tomando este modulo y usaremos el oficial de AWS para crear nuestro cluster de Kubernetes. Más detalles sobre este modulo lo puedes encontrar [aquí](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

Indicaremos nombre y version de nuestro cluster de Kubernetes. Le indicaremos al modulo que el Endpoint será publico de forma que podamos acceder al cluster desde el internet via ``kubectl``. La sección de ``cluster_addons`` nos permite instalar automaticamente caracteristicas adicionales que son necesarias para el correcto funcionamiento de nuestro cluster; puedes ver más detall en la documentación oficial de AWS [aquí](https://docs.aws.amazon.com/es_es/eks/latest/userguide/eks-add-ons.html).

La sección ``vpc_id`` y ``subnet_ids`` nos permite indicarle a nuestro cluster de Kubernetes que use la VPC que creamos anteriormente. La sección ``eks_managed_node_groups`` nos permite crear un grupo de nodos para nuestro cluster de Kubernetes. En este caso vamos a crear un grupo de nodos publico con una instancia de tipo t3.large. La sección ``create_aws_auth_configmap`` y ``manage_aws_auth_configmap`` nos permite crear un archivo de configuración para el acceso al cluster de Kubernetes. La sección ``aws_auth_users`` nos permite indicarle a nuestro cluster de Kubernetes que usuarios van a tener acceso al cluster. Hay otro archivo que podemos crear con el nombre de datasource.tf y vamos a añadir las siguientes líneas:

```hcl
data "aws_iam_user" "me" {
  user_name = "daveops"
}
```
Este archivo nos permite obtener información de un usuario de AWS. En este caso vamos a obtener el nombre de usuario de AWS que vamos a usar para acceder al cluster de Kubernetes. Finalmente añadimos los tags que vamos a añadir a los recursos.

## Comandos terraform

Una vez creado los archivos .tf vamos a ejecutar los siguientes comandos:

```bash
terraform init
terraform plan
terraform apply
```

Estos tres comandos van a descargar los modulos necesarios, crear un plan de ejecución y ejecutar el plan de ejecución. Si todo sale bien nuestro cluster estara listo.

## Acceso al cluster de Kubernetes
Una vez creado nuestro cluster si queremos acceder al cluster de Kubernetes desde nuestra maquina local vamos a tener que instalar el cliente de AWS y el cliente de Kubernetes.

```bash
aws eks --region us-east-1 update-kubeconfig --name youtube-eks
```

y para probar que todo funciona vamos a ejecutar el siguiente comando:

```bash
kubectl get nodes
```

## Eliminar los recursos

Recuerda que al crear estos recursos vamos a generar costos en AWS. Si quieres eliminar los recursos que hemos creado ejecuta el siguiente comando:

```bash
terraform destroy
```

Si quieres conocer el costos de los recursos que hemos creado puedes usar el siguiente [enlace](https://aws.amazon.com/es/eks/pricing/?nc1=h_ls)

Recuerda que si te gusta mi contenido puedes seguirme en mis redes sociales.

- [youtube](https://www.youtube.com/c/DaveOps)
- [Instagram](https://www.instagram.com/thedaveops/)
- [Twitter](https://twitter.com/davejfranco)

