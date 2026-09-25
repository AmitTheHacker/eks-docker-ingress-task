
---

### 📄 FILE 3: `scripts/setup.ps1` (Full Automation Script)

**File: `scripts/setup.ps1`**
```powershell
# ============================================================
# 🚀 EKS + Docker Hub + ALB Ingress — Full Setup Script
# Run this from the project root folder
# Usage: .\scripts\setup.ps1
# ============================================================

param(
    [string]$ClusterName = "my-docker-task",
    [string]$Region = "us-east-1",
    [string]$DockerUser = "YOUR_DOCKERHUB_USERNAME",  # <-- CHANGE THIS!
    [string]$NodeCount = "2",
    [string]$NodeType = "t3.small"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EKS Docker Ingress Task - SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ----------------------------------------------------------
# PHASE 1: DOCKER BUILD & PUSH
# ----------------------------------------------------------
Write-Host "`n[PHASE 1] Building & Pushing Docker Images..." -ForegroundColor Yellow

docker login
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker login failed! Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "Building App V1..." -ForegroundColor Green
docker build -t "$DockerUser/myapp-v1:1.0.0" ./app1
docker push "$DockerUser/myapp-v1:1.0.0"

Write-Host "Building App V2..." -ForegroundColor Green
docker build -t "$DockerUser/myapp-v2:1.0.0" ./app2
docker push "$DockerUser/myapp-v2:1.0.0"

Write-Host "Docker images pushed successfully!" -ForegroundColor Green

# ----------------------------------------------------------
# PHASE 2: EKS CLUSTER CREATION
# ----------------------------------------------------------
Write-Host "`n[PHASE 2] Creating EKS Cluster '$ClusterName'..." -ForegroundColor Yellow
Write-Host "This will take ~12-15 minutes. Grab a coffee! ☕" -ForegroundColor Gray

eksctl create cluster `
    --name $ClusterName `
    --region $Region `
    --version 1.31 `
    --nodegroup-name workers `
    --node-type $NodeType `
    --nodes $NodeCount `
    --nodes-min 1 `
    --nodes-max 3 `
    --with-oidc `
    --managed

Write-Host "Verifying nodes..." -ForegroundColor Green
kubectl get nodes

# ----------------------------------------------------------
# PHASE 3: AWS LOAD BALANCER CONTROLLER
# ----------------------------------------------------------
Write-Host "`n[PHASE 3] Installing AWS Load Balancer Controller..." -ForegroundColor Yellow

# 3a. Download IAM Policy
Write-Host "Downloading IAM policy..." -ForegroundColor Green
curl.exe -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json

# 3b. Create IAM Policy
$ACCOUNT_ID = (aws sts get-caller-identity --query "Account" --output text)
$POLICY_ARN = "arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy-task"

Write-Host "Creating IAM policy..." -ForegroundColor Green
aws iam create-policy `
    --policy-name AWSLoadBalancerControllerIAMPolicy-task `
    --policy-document file://iam_policy.json

# 3c. Create IAM Service Account (IRSA)
Write-Host "Creating IAM Service Account..." -ForegroundColor Green
eksctl create iamserviceaccount `
    --cluster=$ClusterName `
    --namespace=kube-system `
    --name=aws-load-balancer-controller `
    --attach-policy-arn=$POLICY_ARN `
    --override-existing-serviceaccounts `
    --region $Region `
    --approve

# 3d. Install via Helm
Write-Host "Installing controller via Helm..." -ForegroundColor Green
$VPC_ID = (aws eks describe-cluster --name $ClusterName --region $Region `
    --query "cluster.resourcesVpcConfig.vpcId" --output text)

helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
    -n kube-system `
    --set clusterName=$ClusterName `
    --set serviceAccount.create=false `
    --set serviceAccount.name=aws-load-balancer-controller `
    --set region=$Region `
    --set vpcId=$VPC_ID

Write-Host "Waiting for controller to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 30
kubectl get deployment -n kube-system aws-load-balancer-controller

# ----------------------------------------------------------
# PHASE 4: DEPLOY APPLICATIONS
# ----------------------------------------------------------
Write-Host "`n[PHASE 4] Deploying Applications..." -ForegroundColor Yellow

# Update YAML files with actual Docker username
(Get-Content ./k8s/deploy-app1.yaml) -replace 'YOUR_DOCKERHUB_USERNAME', $DockerUser |
    Set-Content ./k8s/deploy-app1.yaml
(Get-Content ./k8s/deploy-app2.yaml) -replace 'YOUR_DOCKERHUB_USERNAME', $DockerUser |
    Set-Content ./k8s/deploy-app2.yaml

kubectl apply -f k8s/deploy-app1.yaml
kubectl apply -f k8s/deploy-app2.yaml

Write-Host "Waiting for pods to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 20
kubectl get pods,svc

# ----------------------------------------------------------
# PHASE 5: APPLY INGRESS
# ----------------------------------------------------------
Write-Host "`n[PHASE 5] Creating ALB Ingress..." -ForegroundColor Yellow

kubectl apply -f k8s/ingress.yaml

Write-Host "`nWaiting 2-3 minutes for ALB to provision..." -ForegroundColor Gray
Write-Host "Run this command to check:" -ForegroundColor Cyan
Write-Host "  kubectl get ingress" -ForegroundColor White
Write-Host "`nThen visit:" -ForegroundColor Cyan
Write-Host "  http://<ALB-ADDRESS>/app1" -ForegroundColor Green
Write-Host "  http://<ALB-ADDRESS>/app2" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE! 🎉" -ForegroundColor Cyan
Write-Host "  Don't forget to run cleanup.ps1 later!" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan