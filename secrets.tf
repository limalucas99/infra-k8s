########################################
# Variável de região usada pelo provider
########################################
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

########################################
# Build do kubeconfig (YAML em string)
########################################
locals {
  kubeconfig = yamlencode({
    apiVersion = "v1"
    kind       = "Config"

    clusters = [{
      name    = aws_eks_cluster.eks.name
      cluster = {
        server                   = aws_eks_cluster.eks.endpoint
        certificate-authority-data = aws_eks_cluster.eks.certificate_authority[0].data
      }
    }]

    contexts = [{
      name    = aws_eks_cluster.eks.name
      context = {
        cluster = aws_eks_cluster.eks.name
        user    = "aws"
      }
    }]

    current-context = aws_eks_cluster.eks.name
    preferences     = {}

    users = [{
      name = "aws"
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args       = [
            "eks", "get-token",
            "--region", var.region,
            "--cluster-name", aws_eks_cluster.eks.name
          ]
        }
      }
    }]
  })
}

########################################
# Segredo (nunca destruído)
########################################
resource "aws_secretsmanager_secret" "eks_info" {
  name        = "eks-academy-cluster-info"
  description = "EKS connection data (endpoint, CA, kubeconfig)"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

########################################
# Nova versão sempre que algo muda
########################################
resource "aws_secretsmanager_secret_version" "eks_info" {
  secret_id = aws_secretsmanager_secret.eks_info.id

  secret_string = jsonencode({
    cluster_name                       = aws_eks_cluster.eks.name
    cluster_endpoint                   = aws_eks_cluster.eks.endpoint
    cluster_certificate_authority_data = aws_eks_cluster.eks.certificate_authority[0].data
    kubeconfig                         = local.kubeconfig      # ← NOVO campo
  })

  # garante nova versão se cluster for recriado
  lifecycle {
    replace_triggered_by = [
      aws_eks_cluster.eks
    ]
  }
}
