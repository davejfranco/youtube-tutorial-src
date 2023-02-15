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

  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  /*
  aws_auth_users = [
    {
      userarn  = data.aws_iam_user.me.arn
      username = "daveops"
      groups   = ["system:masters"]
    }
  ]
  */

  tags = {
    Environment = "tutorial"
    Terraform   = "true"
  }
}

/*
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}
*/