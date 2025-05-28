# Obtém os dados do cluster EKS criado diretamente com aws_eks_cluster
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks.name
}

# Obtém o token de autenticação do EKS
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks.name
}

# Provedor Kubernetes configurado com dados do cluster direto
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Namespace para a aplicação
resource "kubernetes_namespace" "api" {
  metadata {
    name = "api"
  }
}

# Deployment da aplicação
resource "kubernetes_deployment" "api" {
  metadata {
    name      = "api-deployment"
    namespace = kubernetes_namespace.api.metadata[0].name
    labels = {
      app = "api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "api"
      }
    }

    template {
      metadata {
        labels = {
          app = "api"
        }
      }

      spec {
        container {
          name  = "api"
          image = "nginxdemos/hello"  # imagem de teste leve

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Service para expor a aplicação via LoadBalancer
resource "kubernetes_service" "api" {
  metadata {
    name      = "api-service"
    namespace = kubernetes_namespace.api.metadata[0].name
  }

  spec {
    selector = {
      app = "api"
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "LoadBalancer"
  }
}
