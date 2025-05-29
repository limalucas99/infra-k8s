########################################################
# 0. Variável de região (opcional)
########################################################
variable "region" {
  type    = string
  default = "us-east-1"
}

########################################################
# 1. Gera kubeconfig em YAML (string)
########################################################
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
            "eks",
            "get-token",
            "--region", var.region,
            "--cluster-name", aws_eks_cluster.eks.name
          ]
        }
      }
    }]
  })
}

########################################################
# 2. Secret fixo (protegido)
########################################################
resource "aws_secretsmanager_secret" "eks_info" {
  name        = "eks-academy-cluster-info"
  description = "EKS connection data for academy-cluster"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ name ]
  }
}

########################################################
# 3. Versão do segredo (atualiza sempre)
########################################################
resource "aws_secretsmanager_secret_version" "eks_info" {
  secret_id = aws_secretsmanager_secret.eks_info.id

  secret_string = jsonencode({
    cluster_name                       = aws_eks_cluster.eks.name
    cluster_endpoint                   = aws_eks_cluster.eks.endpoint
    cluster_certificate_authority_data = aws_eks_cluster.eks.certificate_authority[0].data
    kubeconfig                         = local.kubeconfig            # ← novo campo
  })
}
