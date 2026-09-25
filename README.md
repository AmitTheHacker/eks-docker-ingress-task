# 🚀 Multi-App Deployment on AWS EKS with ALB Ingress

## 📌 Project Overview

This project demonstrates a **production-grade workflow** of deploying
multiple Dockerized web applications on **Amazon EKS (Elastic Kubernetes
Service)** using **Docker Hub** as the container registry and **AWS ALB
(Application Load Balancer) Ingress Controller** for path-based routing.

Two versions of a web app are deployed behind a **single ALB**:
- `/app1` → Version 1 (Green UI)
- `/app2` → Version 2 (Red UI)

---

## 🏗️ Architecture Diagram

                Internet
                   │
                   ▼
        ┌─────────────────────┐
        │   AWS ALB (L7 LB)   │
        │  k8s-xxxxx.elb.aws  │
        └──────┬───────┬──────┘
               │       │
        /app1  │       │  /app2
               ▼       ▼
     ┌──────────┐  ┌──────────┐
     │ Target   │  │ Target   │
     │ Group 1  │  │ Group 2  │
     └────┬─────┘  └────┬─────┘
          │              │
 ┌────────▼───┐  ┌──────▼─────┐
 │  App V1    │  │  App V2    │
 │  Pod1 Pod2 │  │  Pod1 Pod2 │
 │  (nginx)   │  │  (nginx)   │
 └────────────┘  └────────────┘
     EKS Cluster (2x t3.small)


---

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Container Runtime | Docker |
| Container Registry | Docker Hub (Public) |
| Orchestration | Amazon EKS (Kubernetes 1.31) |
| Ingress Controller | AWS Load Balancer Controller v2.14 |
| Load Balancer | AWS ALB (Application Load Balancer) |
| IaC / Cluster Tool | eksctl |
| Package Manager | Helm v3 |
| CI/CD (Future) | GitHub Actions (planned) |

---

## 📋 Prerequisites

| Tool | Version | Install Command |
|---|---|---|
| Docker Desktop | 27.x+ | [Download](https://docker.com) |
| AWS CLI | 2.x+ | `winget install Amazon.AWSCLI` |
| kubectl | 1.31+ | `winget install Kubernetes.kubectl` |
| eksctl | 0.190+ | `winget install eksctl.eksctl` |
| Helm | 3.x+ | `winget install Helm.Helm` |
| AWS Account | Free Tier | [Sign Up](https://aws.amazon.com) |

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/eks-docker-ingress-task.git
cd eks-docker-ingress-task

### 2. Run Automated Setup
```PowerShell

.\scripts\setup.ps1

### 3. Access the Apps
### Wait 2-3 minutes after setup, then:

```bash
kubectl get ingress
# Visit: http://<ALB-ADDRESS>/app1
# Visit: http://<ALB-ADDRESS>/app2

### 4. Cleanup (IMPORTANT — Save Money!)
```PowerShell

.\scripts\cleanup.ps1