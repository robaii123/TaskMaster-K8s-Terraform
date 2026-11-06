output "namespace" {
  description = "Namespace Kubernetes actif"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "web_service_name" {
  description = "Nom du Service LoadBalancer Web"
  value       = kubernetes_service.web_service.metadata[0].name
}

output "port_forward_command" {
  description = "Commande rapide pour ouvrir le tunnel local vers le cluster"
  value       = "kubectl port-forward svc/${kubernetes_service.web_service.metadata[0].name} -n ${kubernetes_namespace.app_namespace.metadata[0].name} 8080:8080"
}