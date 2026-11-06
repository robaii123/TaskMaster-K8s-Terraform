# 1. Le disque dur persistant de 1 Go (PVC)
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  wait_until_bound = false
}

# 2. Le Deployment PostgreSQL
resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres-deployment"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          image = "postgres:16-alpine"
          name  = "postgres"

          port {
            container_port = 5432
          }

          # Injection dynamique du Secret créé dans main.tf
          env_from {
            secret_ref {
              name = kubernetes_secret.db_secret.metadata[0].name
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# 3. Le Service Interne (ClusterIP)
resource "kubernetes_service" "postgres_service" {
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}