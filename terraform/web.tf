# 1. Le Deployment de l'application Web (Flask / Gunicorn)
resource "kubernetes_deployment" "web" {
  metadata {
    name      = "web-deployment"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = var.web_replicas

    selector {
      match_labels = {
        app = "taskmaster-web"
      }
    }

    template {
      metadata {
        labels = {
          app = "taskmaster-web"
        }
      }

      spec {
        container {
          image = "robaii/taskmaster:latest"
          name  = "web"

          port {
            container_port = 5000
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.db_secret.metadata[0].name
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }
        }
      }
    }
  }
}

# 2. Le Service LoadBalancer pour exposer l'application
resource "kubernetes_service" "web_service" {
  metadata {
    name      = "web-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "taskmaster-web"
    }

    port {
      port        = 8080
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}