@'
# 🚀 Multi-App Deployment on AWS EKS with ALB Ingress

## 📌 Project Overview
This project demonstrates a production-grade workflow of deploying multiple Dockerized web applications on Amazon EKS using Docker Hub as the container registry and the AWS ALB Ingress Controller for path-based routing.

Two distinct application versions are deployed behind a single Application Load Balancer:
- Path `/app1` -> Routes to **App Version 1** (Green Theme)
- Path `/app2` -> Routes to **App Version 2** (Red Theme)

---

## 🏗️ Architecture Diagram

                    Internet / Users
                           │
                           ▼
            ┌─────────────────────────────┐
            │   AWS Application LB (ALB)  │
            │  k8s-mysharedalb-xxxxx.elb  │
            └──────────────┬──────────────┘
                           │
             ┌─────────────┴─────────────┐
             │ Path-Based Routing Rules  │
             └─────────────┬─────────────┘
                    │              │
           Path: /app1│              │Path: /app2
                    ▼              ▼
         ┌──────────────────┐  ┌──────────────────┐
         │ Target Group 1   │  │ Target Group 2   │
         └────────┬─────────┘  └────────┬─────────┘
                  │                     │
          ┌───────▼────────┐    ┌───────▼────────┐
          │ App V1 Service │    │ App V2 Service │
          └───────┬────────┘    └───────┬────────┘
                  │                     │
         ┌────────┴────────┐   ┌────────┴────────┐
         │ App V1 Pods (2) │   │ App V2 Pods (2) │
         │ (Nginx Alpine)  │   │ (Nginx Alpine)  │
         └─────────────────┘   └─────────────────┘
           EKS Managed Cluster (2x t3.small Nodes)

---

## 🛠️ Tech Stack & Tools

| Layer | Technology |
|---|---|
| **Container Engine** | Docker Desktop |
| **Image Registry** | Docker Hub (Semantic Tagging: `1.0.1`) |
| **Orchestration** | Amazon EKS (Kubernetes v1.34) |
| **Ingress Controller** | AWS Load Balancer Controller (v2.14) via Helm |
| **Cloud Provider** | AWS (ALB, IAM OIDC / IRSA, EC2, VPC) |
| **IaC & Tooling** | `eksctl v0.230.0`, `kubectl`, `helm v3`, PowerShell |

---

## 📋 Prerequisites

| Tool | Version | Install Command |
|---|---|---|
| Docker Desktop | 27.x+ | https://docker.com |
| AWS CLI | 2.x+ | `winget install Amazon.AWSCLI` |
| kubectl | 1.34+ | `winget install Kubernetes.kubectl` |
| eksctl | 0.230+ | `winget install eksctl.eksctl` |
| Helm | 3.x+ | `winget install Helm.Helm` |

---

## 🚀 Quick Start (Automated)

### 1. Clone the Repository
```powershell
git clone https://github.com/AmitTheHacker/eks-docker-ingress-task.git
cd eks-docker-ingress-task



          