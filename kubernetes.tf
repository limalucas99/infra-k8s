# Dados do cluster existente
data "aws_eks_cluster" "cluster" { name = aws_eks_cluster.eks.name }
data "aws_eks_cluster_auth" "cluster" { name = aws_eks_cluster.eks.name }

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Namespace
resource "kubernetes_namespace" "api" {
  metadata { name = "api" }
}

# Deployment (skip wait)
resource "kubernetes_deployment" "api" {
  metadata {
    name      = "api-deployment"
    namespace = kubernetes_namespace.api.metadata[0].name
    labels    = { app = "api" }
  }

  wait_for_rollout = false   # evita travar o apply

  spec {
    replicas = 2
    selector { match_labels = { app = "api" } }

    template {
      metadata { labels = { app = "api" } }
      spec {
        container {
          name  = "api"
          image = "nginxdemos/hello"
          port  { container_port = 80 }
        }
      }
    }
  }
}

# Service (LoadBalancer)
resource "kubernetes_service" "api" {
  metadata {
    name      = "api-service"
    namespace = kubernetes_namespace.api.metadata[0].name
  }

  spec {
    selector = { app = "api" }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
