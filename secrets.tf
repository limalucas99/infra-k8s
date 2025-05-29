########################################################
#  Segredo único — nome fixo, nunca destruído
########################################################
resource "aws_secretsmanager_secret" "eks_info" {
  name        = "eks-academy-cluster-info"          # ← nome estável
  description = "EKS connection data for academy-cluster"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ name ]   # se o provider tentar alterar o nome, ignore
  }
}

resource "aws_secretsmanager_secret_version" "eks_info" {
  secret_id = aws_secretsmanager_secret.eks_info.id

  # Sempre grava uma NOVA versão (não recria o segredo)
  secret_string = jsonencode({
    cluster_name                     = aws_eks_cluster.eks.name
    cluster_endpoint                 = aws_eks_cluster.eks.endpoint
    cluster_certificate_authority_data = aws_eks_cluster.eks.certificate_authority[0].data
  })
}
