provider "aws" {
  region = "us-east-1"
}

# Role manual do Academy (já existente, como a labRole)
data "aws_iam_role" "eks_cluster_role" {
  name = "labRole" # Troque se for outro nome da sua role
}

# VPC simplificada (ou use a que já existe)
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

# Security Group para o cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS cluster SG"
  vpc_id      = aws_vpc.main.id
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "academy-cluster"
  role_arn = data.aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  version = "1.29"

  depends_on = [aws_security_group.eks_cluster_sg]
}

# IAM Role para o Node Group (pode ser a mesma do labRole ou outra criada manualmente)
data "aws_iam_role" "eks_node_role" {
  name = "labRole" # Reutilize a mesma se necessário
}

# Node Group gerenciado
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
}
