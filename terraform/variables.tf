variable "namespace_name" {
    description = "Nom de namespace Kubernates"
    type = string
    default = "taskmaster"
}

variable "web_replicas" {
    description = "Nombre de Pods Flask/Gunicorn en parallele"
    type = number
    default = 3
}

variable "db_password" {
    description = "Mode de passe Postgres"
    type = string
    default = "secretpassword"
    sensitive = true
}