########################################
# Segredo único (usa name_prefix)
########################################
resource "aws_secretsmanager_secret" "eks_info" {
  name_prefix  = "eks-${aws_eks_cluster.eks.name}-info-"
  description  = "EKS connection data for ${aws_eks_cluster.eks.name}"
  lifecycle { prevent_destroy = true } # não apaga em destroy
}

resource "aws_secretsmanager_secret_version" "eks_info" {
  secret_id = aws_secretsmanager_secret.eks_info.id
  secret_string = jsonencode({
    cluster_name                     = aws_eks_cluster.eks.name
    cluster_endpoint                 = aws_eks_cluster.eks.endpoint
    cluster_certificate_authority_data = aws_eks_cluster.eks.certificate_authority[0].data
  })
}
