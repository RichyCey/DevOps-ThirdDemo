provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket                  = "softserve-demo-terraform-s3-state"
    key                     = "my-terraform-project"
    region                  = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

module "ecr" {
  source           = "./modules/ecr"
  ecr_name         = var.ecr_name
  tags             = var.tags
  image_mutability = var.image_mutability
}

module "network" {
  source = "./modules/network"
}

module "eks" {
  source = "./modules/eks"
  private_subnet_id_us_east_1a = module.network.private-us-east-1a
  private_subnet_id_us_east_1b = module.network.private-us-east-1b
  public_subnet_id_us_east_1a  = module.network.public-us-east-1a
  public_subnet_id_us_east_1b  = module.network.public-us-east-1b
}

# 0-provider.tf

module "iam" {
  source      = "./modules/iam"
  eks_url     =  module.eks.demo.identity[0].oidc[0].issuer
  role_name   = "test-oidc"
  policy_name = "test-policy"

  policy_json = jsonencode({
    Statement = [{
      Action   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
      Effect   = "Allow"
      Resource = "arn:aws:s3:::*"
    }]
    Version   = "2012-10-17"
  })
}
