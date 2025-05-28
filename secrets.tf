########################################
# 1. Secrets Manager – segredo “único”
########################################
resource "aws_secretsmanager_secret" "eks_info" {
  name = "eks-${aws_eks_cluster.eks.name}-info"   #  ex.: eks-academy-cluster-info
  description = "EKS connection data for ${aws_eks_cluster.eks.name}"
}

resource "aws_secretsmanager_secret_version" "eks_info" {
  secret_id = aws_secretsmanager_secret.eks_info.id

  # grava tudo como JSON
  secret_string = jsonencode({
    cluster_name                     = aws_eks_cluster.eks.name
    cluster_endpoint                 = aws_eks_cluster.eks.endpoint
    cluster_certificate_authority_data = aws_eks_cluster.eks.certificate_authority[0].data
  })
}
