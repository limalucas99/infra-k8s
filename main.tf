#########################################################
# 0. Terraform & provider
#########################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

#########################################################
# 1. IAM Roles (pré-existentes no AWS Academy)
#########################################################
data "aws_iam_role" "eks_cluster_role" {
  name = "labRole"
}

data "aws_iam_role" "eks_node_role" {
  name = "labRole"
}

#########################################################
# 2. Rede mínima
#########################################################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS cluster SG"
  vpc_id      = aws_vpc.main.id
}

#########################################################
# 3. Cluster EKS
#########################################################
resource "aws_eks_cluster" "eks" {
  name     = "academy-cluster"
  version  = "1.29"
  role_arn = data.aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
}

#########################################################
# 4. Node Group gerenciado
#########################################################
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "academy-node-group"
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t2.micro"]

  depends_on = [aws_eks_cluster.eks]
}

#########################################################
# 5. Outputs
#########################################################
output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_certificate_authority_data" {
  value     = aws_eks_cluster.eks.certificate_authority[0].data
  sensitive = true
}
