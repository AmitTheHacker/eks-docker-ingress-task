# ============================================================
# 🧹 EKS + ALB + IAM — Complete Cleanup Script
# Run this AFTER you're done practicing to STOP BILLING
# Usage: .\scripts\cleanup.ps1
# ============================================================

param(
    [string]$ClusterName = "my-docker-task",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Continue"  # Don't stop on errors

Write-Host "========================================" -ForegroundColor Red
Write-Host "  EKS Docker Ingress Task - CLEANUP" -ForegroundColor Red
Write-Host "  This will DELETE everything!" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red

$confirm = Read-Host "Are you sure? Type 'YES' to continue"
if ($confirm -ne "YES") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

# ----------------------------------------------------------
# STEP 1: Delete Ingress (ALB will auto-delete)
# ----------------------------------------------------------
Write-Host "`n[1/6] Deleting Ingress & ALB..." -ForegroundColor Yellow
kubectl delete -f k8s/ingress.yaml --ignore-not-found
Write-Host "Waiting 2 minutes for ALB to fully delete..." -ForegroundColor Gray
Start-Sleep -Seconds 120

# ----------------------------------------------------------
# STEP 2: Delete Deployments & Services
# ----------------------------------------------------------
Write-Host "`n[2/6] Deleting Deployments & Services..." -ForegroundColor Yellow
kubectl delete -f k8s/deploy-app1.yaml --ignore-not-found
kubectl delete -f k8s/deploy-app2.yaml --ignore-not-found

# ----------------------------------------------------------
# STEP 3: Uninstall Helm Controller
# ----------------------------------------------------------
Write-Host "`n[3/6] Uninstalling ALB Controller..." -ForegroundColor Yellow
helm uninstall aws-load-balancer-controller -n kube-system

# ----------------------------------------------------------
# STEP 4: Delete EKS Cluster (takes 10-15 mins)
# ----------------------------------------------------------
Write-Host "`n[4/6] Deleting EKS Cluster '$ClusterName'..." -ForegroundColor Yellow
Write-Host "This will take ~10-15 minutes..." -ForegroundColor Gray
eksctl delete cluster --name $ClusterName --region $Region

# ----------------------------------------------------------
# STEP 5: Delete IAM Policy
# ----------------------------------------------------------
Write-Host "`n[5/6] Deleting IAM Policy..." -ForegroundColor Yellow
$ACCOUNT_ID = (aws sts get-caller-identity --query "Account" --output text)
$POLICY_ARN = "arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy-task"
aws iam delete-policy --policy-arn $POLICY_ARN

# ----------------------------------------------------------
# STEP 6: Local File Cleanup
# ----------------------------------------------------------
Write-Host "`n[6/6] Cleaning local files..." -ForegroundColor Yellow
Remove-Item -Force iam_policy.json -ErrorAction SilentlyContinue

# ----------------------------------------------------------
# VERIFICATION
# ----------------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  CLEANUP COMPLETE! ✅" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nPlease verify in AWS Console:" -ForegroundColor Cyan
Write-Host "  1. EC2 → Instances (should be empty)" -ForegroundColor White
Write-Host "  2. VPC → VPCs (no extra VPC)" -ForegroundColor White
Write-Host "  3. EC2 → Load Balancers (should be empty)" -ForegroundColor White
Write-Host "  4. CloudFormation → Stacks (no eksctl stacks)" -ForegroundColor White
Write-Host "  5. IAM → Roles (no eksctl roles left)" -ForegroundColor White
Write-Host "`n💰 Your bill should be ~$0.30-0.50 total!" -ForegroundColor Green