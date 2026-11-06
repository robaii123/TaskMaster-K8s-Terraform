terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

# Configuration du Provider : il lit automatiquement ton cluster Docker Desktop / Kind !
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# 1. Création du Namespace (Equivalent de 01-namespace-secret.yml)
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    # Appelle ici la variable namespace_name définie dans variables.tf :
    name = var.namespace_name
  }
}

# 2. Création du Secret (Equivalent de db-credentials)
resource "kubernetes_secret" "db_secret" {
  metadata {
    name      = "db-credentials"
    # Regarde cette syntaxe pro : on lie directement le Secret au Namespace créé juste au-dessus !
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    POSTGRES_DB       = "taskdb"
    POSTGRES_USER     = "postgres"
    POSTGRES_PASSWORD = var.db_password
    DB_NAME           = "taskdb"
    DB_HOST           = "postgres-service"
    DB_USER           = "postgres"
    DB_PASS           = var.db_password
  }

  type = "Opaque"
}