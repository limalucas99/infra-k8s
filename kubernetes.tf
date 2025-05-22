provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "api" {
  metadata {
    name = "api"
  }
}

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
          image = "seuuser/sua-api:latest" # Altere aqui com sua imagem Docker

          port {
            container_port = 8000
          }
        }
      }
    }
  }
}

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
