#########################################################
# 0.  Terraform & Provider
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
# 1.  IAM Roles (pré-existentes no AWS Academy)
#########################################################
data "aws_iam_role" "eks_cluster_role" {
  name = "labRole"
}

data "aws_iam_role" "eks_node_role" {
  name = "labRole"
}

#########################################################
# 2.  Rede mínima
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
# 3.  Clean-up: remove cluster antigo se existir
#########################################################
resource "null_resource" "eks_cleanup" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    # usa /usr/bin/env para portabilidade
    interpreter = ["/usr/bin/env", "bash", "-c"]

    command = <<-EOT
      set -euo pipefail

      if aws eks describe-cluster --name academy-cluster >/dev/null 2>&1; then
        echo "Cluster antigo encontrado. Excluindo..."
        aws eks delete-cluster --name academy-cluster
        echo "Aguardando remoção completa..."
        aws eks wait cluster_deleted --name academy-cluster
        echo "Cluster removido com sucesso."
      else
        echo "Nenhum cluster com o nome 'academy-cluster' foi encontrado."
      fi
    EOT
  }
}

#########################################################
# 4.  Novo cluster EKS
#########################################################
resource "aws_eks_cluster" "eks" {
  name     = "academy-cluster"
  role_arn = data.aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  version    = "1.29"
  depends_on = [
    null_resource.eks_cleanup,
    aws_security_group.eks_cluster_sg
  ]
}

#########################################################
# 5.  Node Group
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
# 6.  Outputs (únicos)
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
