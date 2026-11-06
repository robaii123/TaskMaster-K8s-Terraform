# ☸️ TaskMaster — Orchestration Kubernetes & Infrastructure as Code (Terraform)

![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.36-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-HCL_IaC-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker_Hub-robaii%2Ftaskmaster-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16--Alpine_PVC-336791?style=for-the-badge&logo=postgresql&logoColor=white)

Dépôt d'infrastructure (**Infra Repo**) dédié au déploiement haute disponibilité de l'application **TaskMaster** sur un cluster **Kubernetes**, provisionné de manière déclarative via ** manifestes YAML natifs (`k8s/`)** et automatisé en **Infrastructure as Code avec Terraform (`terraform/`)**.

> 🔗 **Dépôt de l'application & Pipeline CI/CD DevSecOps :** [DevOps-Project-TaskMaster](https://github.com/robaii123/DevOps-Project-TaskMaster)

---

## 🏗️ Architecture Kubernetes Déployée

L'ensemble des ressources est isolé dans le namespace dédié **`taskmaster`** :

```text
[ Navigateur / Client (:8080) ]
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Namespace : taskmaster                                  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Service : web-service (LoadBalancer :8080 -> :5000)│  │
│  └───────────┬──────────────────┬──────────────────┬──┘  │
│              ▼                  ▼                  ▼     │
│     ┌─────────────────┐┌─────────────────┐┌────────────┐ │
│     │ Pod Web (Rep 1) ││ Pod Web (Rep 2) ││Pod Web (3) │ │ ◄── Probes HTTP (/health)
│     │ Gunicorn :5000  ││ Gunicorn :5000  ││Gunicorn    │ │     Auto-Healing & Scaling
│     └────────┬────────┘└────────┬────────┘└─────┬──────┘ │
│              └──────────────────┼───────────────┘        │
│                                 ▼                        │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Service : postgres-service (ClusterIP :5432)       │  │ ◄── Réseau interne privé
│  └──────────────────────────────┬─────────────────────┘  │
│                                 ▼                        │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Pod : postgres-deployment (postgres:16-alpine)     │  │ ◄── Secret : db-credentials
│  └──────────────────────────────┬─────────────────────┘  │
│                                 ▼                        │
│  ┌────────────────────────────────────────────────────┐  │
│  │ PersistentVolumeClaim : postgres-pvc (1Gi - RWO)   │  │ ◄── Stockage SQL persistant
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## ✨ Concepts Clés Implémentés

### 1. Orchestration Kubernetes (`k8s/`)
* **Isolation & Sécurité (`01-namespace-secret.yml`) :** Cloisonnement dans le namespace `taskmaster` et injection des identifiants SQL via un objet `Secret` (`Opaque`) monté avec `envFrom`.
* **Persistance Stateful (`02-postgres.yml`) :** Allocation d'un disque persistant de `1Gi` via un `PersistentVolumeClaim` (`ReadWriteOnce`) monté sur `/var/lib/postgresql/data` et exposé uniquement en interne (`ClusterIP`).
* **Haute Disponibilité & Self-Healing (`03-web.yml`) :** Déploiement de **3 réplicas** (`robaii/taskmaster:latest`) supervisés par des sondes **`readinessProbe`** et **`livenessProbe`** sur l'endpoint `/health` (port `5000`).

### 2. Automatisation Infrastructure as Code (`terraform/`)
* **Provider Kubernetes (`main.tf`) :** Pilotage automatisé du cluster Kubernetes et gestion des dépendances implicites entre ressources (Namespace ➔ Secret ➔ PVC ➔ Deployments).
* **Paramétrage Dynamique (`variables.tf`) :** Externalisation du nombre de réplicas (`var.web_replicas`), du namespace (`var.namespace_name`) et protection des mots de passe (`sensitive = true`).
* **Scaling à la volée :** Possibilité de redimensionner la flotte de Pods sans modifier le code via `terraform apply -var="web_replicas=5"`.

---

## 📂 Structure du Dépôt

```text
TaskMaster-K8s-Terraform/
├── k8s/                          # Approche 1 : Manifestes YAML Kubernetes natifs
│   ├── 01-namespace-secret.yml   # Namespace 'taskmaster' & Secret 'db-credentials'
│   ├── 02-postgres.yml           # PVC (1Gi), Deployment PostgreSQL & Service ClusterIP
│   └── 03-web.yml                # Deployment Flask/Gunicorn (3 replicas + Probes) & LoadBalancer
├── terraform/                    # Approche 2 : Infrastructure as Code (HCL)
│   ├── main.tf                   # Provider Kubernetes, Namespace & Secret
│   ├── variables.tf              # Variables dynamiques (namespace, replicas, db_password)
│   ├── postgres.tf               # Provisionnement Stateful PostgreSQL (PVC, Deployment, Service)
│   ├── web.tf                    # Provisionnement Stateless Web (Deployment, Probes, LoadBalancer)
│   └── outputs.tf                # Sorties utiles après déploiement
├── .gitignore                    # Exclusion stricte des fichiers .tfstate et binaires .terraform/
└── README.md
```

---

## 🚀 Démarrage Rapide

### Option A — Déploiement automatisé avec Terraform (Recommandé)

```bash
cd terraform

# 1. Initialiser le provider Kubernetes
terraform init

# 2. Prévisualiser le plan d'infrastructure
terraform plan

# 3. Provisionner toute la stack dans le cluster
terraform apply -auto-approve

# (Optionnel) Scaler dynamiquement à 5 Pods Web
terraform apply -var="web_replicas=5" -auto-approve
```

### Option B — Déploiement déclaratif avec `kubectl`

```bash
kubectl apply -f k8s/01-namespace-secret.yml
kubectl apply -f k8s/02-postgres.yml
kubectl apply -f k8s/03-web.yml
```

---

## 🔍 Vérification & Accès à l'application

```bash
# Vérifier l'état des Pods, Services et du Volume Persistant (PVC)
kubectl get pods,svc,pvc -n taskmaster

# Ouvrir le tunnel local vers le LoadBalancer Kubernetes
kubectl port-forward svc/web-service -n taskmaster 8080:8080
```
* **Interface Web :** [http://localhost:8080](http://localhost:8080)
* **Healthcheck :** [http://localhost:8080/health](http://localhost:8080/health)
