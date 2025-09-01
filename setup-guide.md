# 🚀 Complete Setup & Testing Guide

## Prerequisites Installation

### 1. Install Required Tools
```bash
# Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo apt update && sudo apt install terraform

# Security Tools
npm install -g @semgrep/cli
```

## Phase 1: Application Setup & Testing

### 1.1 Create Project Structure
```bash
# Create main directory
mkdir devsecops-nodejs-api
cd devsecops-nodejs-api

# Create all subdirectories
mkdir -p .github/workflows terraform k8s/policies falco monitoring docs
```

### 1.2 Setup Application
```bash
# Copy all files to their respective locations
# (Use the files I created above)

# Install Node.js dependencies
npm install

# Run unit tests
npm test

# Test security scans locally
npm run security:audit
```

### 1.3 Test Application Locally
```bash
# Start application
npm start

# Test endpoints in another terminal
curl http://localhost:3000/health
curl http://localhost:3000/api/users
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'
```

**Expected Results:**
- ✅ Health endpoint returns `{"status":"healthy"}`
- ✅ Users endpoint returns array of users
- ✅ POST creates user with ID
- ✅ All tests pass (npm test)

## Phase 2: Container Testing

### 2.1 Build Secure Container
```bash
# Build multi-stage Docker image
docker build -t devsecops-api .

# Verify non-root user
docker run --rm devsecops-api id
# Expected: uid=1001(nodejs) gid=1001(nodejs)

# Test health check
docker run -p 3000:3000 devsecops-api &
sleep 10
curl http://localhost:3000/health
docker stop $(docker ps -q)
```

### 2.2 Container Security Testing
```bash
# Install container security tools
# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Container structure test
curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
chmod +x container-structure-test-linux-amd64
sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

# Run security scans
trivy image devsecops-api
container-structure-test test --image devsecops-api --config container-structure-test.yaml
```

**Expected Results:**
- ✅ Trivy shows 0 critical vulnerabilities
- ✅ Container structure tests pass
- ✅ Container runs as non-root user
- ✅ Health check works

## Phase 3: Infrastructure Testing

### 3.1 Terraform Setup
```bash
cd terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your AWS credentials/region
# terraform.tfvars:
# aws_region = "us-west-2"
# environment = "dev"
```

### 3.2 Infrastructure Security Testing
```bash
# Install IaC security tools
pip3 install checkov
wget -O - https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Test Terraform configuration
terraform init
terraform validate
terraform fmt -check

# Run security scans
checkov -d . --framework terraform
tfsec .

# Plan deployment (don't apply yet)
terraform plan
```

**Expected Results:**
- ✅ Terraform validation passes
- ✅ Checkov shows no critical findings
- ✅ TFSec shows secure configuration
- ✅ Plan shows encrypted S3 bucket creation

## Phase 4: Kubernetes Testing

### 4.1 Start Minikube
```bash
# Start minikube with security features
minikube start --driver=docker --cpus=4 --memory=8192

# Enable necessary addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### 4.2 Deploy Application
```bash
cd ../k8s

# Apply in order
kubectl apply -f namespace.yaml
kubectl apply -f rbac.yaml
kubectl apply -f service.yaml
kubectl apply -f deployment.yaml

# Wait for deployment
kubectl rollout status deployment/devsecops-nodejs-api -n devsecops-app
```

### 4.3 Test Kubernetes Security
```bash
# Check pod security
kubectl get pods -n devsecops-app -o yaml | grep -A5 securityContext

# Test network policy (this should fail)
kubectl run test-pod --rm -it --image=busybox -- wget http://devsecops-nodejs-api-svc.devsecops-app.svc.cluster.local

# Check RBAC
kubectl auth can-i get pods --as=system:serviceaccount:devsecops-app:devsecops-app-sa -n devsecops-app
```

**Expected Results:**
- ✅ Pods running with security context
- ✅ Network policy blocks unauthorized access
- ✅ RBAC restricts service account permissions
- ✅ Application responds to health checks

## Phase 5: Runtime Security Testing

### 5.1 Install OPA Gatekeeper
```bash
# Install OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# Wait for gatekeeper to be ready
kubectl wait --for=condition=Ready pod -l gatekeeper.sh/operation=webhook -n gatekeeper-system --timeout=300s

# Apply our policies
kubectl apply -f policies/opa-gatekeeper.yaml
```

### 5.2 Test OPA Policies
```bash
# Try to deploy a bad pod (should be rejected)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-deployment
  namespace: devsecops-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bad-app
  template:
    metadata:
      labels:
        app: bad-app
    spec:
      containers:
      - name: bad-container
        image: nginx
        securityContext:
          privileged: true
EOF
```

### 5.3 Test Falco (Optional)
```bash
cd ../
docker-compose up -d falco

# Generate test alerts
kubectl exec -it deployment/devsecops-nodejs-api -n devsecops-app -- /bin/bash
# This should trigger "Shell Spawned in Container" alert

# Check Falco logs
docker-compose logs falco | grep -i "priority"
```

**Expected Results:**
- ✅ OPA Gatekeeper rejects privileged deployment
- ✅ Falco detects shell spawning in container
- ✅ Policies enforce security requirements

## Phase 6: CI/CD Testing

### 6.1 GitHub Setup
```bash
# Initialize git repository
git init
git add .
git commit -m "Initial DevSecOps implementation"

# Create GitHub repository and push
git remote add origin https://github.com/YOUR-USERNAME/devsecops-nodejs-api.git
git branch -M main
git push -u origin main
```

### 6.2 Setup GitHub Secrets
Go to GitHub Repository → Settings → Secrets and variables → Actions

Add these secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key  
- `SEMGREP_APP_TOKEN`: (Optional) Semgrep token
- `CODECOV_TOKEN`: (Optional) Codecov token

### 6.3 Test CI/CD Pipeline
```bash
# Make a test change to trigger pipeline
echo "# Test change" >> README.md
git add README.md
git commit -m "Test CI/CD pipeline"
git push
```

**Expected Results:**
- ✅ Pipeline runs all security scans
- ✅ No critical vulnerabilities found
- ✅ Container builds successfully
- ✅ All tests pass

## Phase 7: Complete System Test

### 7.1 End-to-End Test
```bash
# Test complete flow
kubectl port-forward svc/devsecops-nodejs-api-svc 8080:80 -n devsecops-app &

# Test application through Kubernetes
curl http://localhost:8080/health
curl http://localhost:8080/api/users

# Check all components
kubectl get all -n devsecops-app
kubectl get networkpolicy -n devsecops-app
kubectl get constrainttemplates
```

### 7.2 Security Validation Checklist
```bash
# Run final security validation
echo "🔍 Security Validation Checklist"
echo "================================"

# 1. Container Security
echo "1. Container Security:"
docker run --rm devsecops-api whoami
trivy image devsecops-api | grep -i critical

# 2. Kubernetes Security  
echo "2. Kubernetes Security:"
kubectl get pods -n devsecops-app -o jsonpath='{.items[0].spec.securityContext}'

# 3. Network Security
echo "3. Network Security:"
kubectl get networkpolicy -n devsecops-app

# 4. Policy Enforcement
echo "4. Policy Enforcement:"
kubectl get constraintviolations -A

# 5. Monitoring
echo "5. Security Monitoring:"
docker-compose ps | grep falco
```

## 🎯 Success Criteria

Your implementation is successful if:

✅ **Application Tests Pass**
- All unit tests pass (npm test)
- API endpoints respond correctly
- Health checks work

✅ **Security Scans Pass**  
- Trivy shows 0 critical container vulnerabilities
- Checkov/TFSec show secure infrastructure
- Semgrep shows no critical code issues

✅ **Container Security**
- Container runs as non-root user
- Read-only filesystem enforced
- No privileged containers

✅ **Kubernetes Security**
- Pod Security Standards enforced
- RBAC working correctly
- Network policies blocking unauthorized access

✅ **Policy Enforcement**
- OPA Gatekeeper rejecting bad deployments
- No constraint violations

✅ **CI/CD Pipeline**
- All pipeline stages complete successfully
- Security gates working (blocks on critical findings)
- Automated deployment works

## 🚨 Troubleshooting Common Issues

### Issue: Container fails to start
```bash
# Check container logs
docker logs <container-id>
# Usually: permissions issue or missing dependencies
```

### Issue: Kubernetes pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n devsecops-app
# Usually: security context or image pull issues
```

### Issue: Network policy blocking everything
```bash
# Check network policy configuration
kubectl describe networkpolicy -n devsecops-app
# Temporarily disable for testing:
# kubectl delete networkpolicy devsecops-app-netpol -n devsecops-app
```

### Issue: OPA policies too restrictive
```bash
# Check constraint violations
kubectl get constraintviolations -A
# Adjust policies in k8s/policies/opa-gatekeeper.yaml
```

## 📊 Performance Benchmarks

Expected performance after full setup:
- Application startup: < 10 seconds
- API response time: < 100ms
- Container build time: < 5 minutes  
- Kubernetes deployment: < 2 minutes
- Security scan time: < 3 minutes
- Full CI/CD pipeline: < 15 minutes