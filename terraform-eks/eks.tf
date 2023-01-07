module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "youtube-eks"
  cluster_version = "1.24"

  create_kms_key                 = true
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
  subnet_ids = module.vpc.public_subnets

  create_node_security_group = true
  eks_managed_node_groups = {
    public = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  # aws-auth configmap
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  #   aws_auth_roles = [
  #     {
  #       rolearn  = "arn:aws:iam::66666666666:role/role1"
  #       username = "role1"
  #       groups   = ["system:masters"]
  #     },
  #   ]

  aws_auth_users = [
    {
      userarn  = data.aws_iam_user.me.arn
      username = "dave"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Environment = "tutorial"
    Terraform   = "true"
  }
}