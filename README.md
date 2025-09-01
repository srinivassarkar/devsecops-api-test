# DevSecOps Node.js API Project

A comprehensive DevSecOps implementation demonstrating security integration throughout the software development lifecycle - from code to infrastructure to runtime.

## 🎯 Project Overview

This project implements a secure Node.js REST API with comprehensive security controls at every stage:

- **Dev**: Secure coding practices, SAST scanning, dependency management
- **Sec**: Security scanning, policy enforcement, vulnerability management  
- **Ops**: Infrastructure as Code, container security, runtime monitoring

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Development   │    │    Security     │    │   Operations    │
│                 │    │                 │    │                 │
│ • Node.js API   │────│ • SAST (Semgrep)│────│ • Kubernetes    │
│ • Unit Tests    │    │ • SCA (Trivy)   │    │ • Docker        │
│ • Code Quality  │    │ • IaC Scanning  │    │ • Terraform     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                    ┌─────────────────┐
                    │   Runtime Sec   │
                    │                 │
                    │ • OPA Policies  │
                    │ • Falco         │
                    │ • Network Pol   │
                    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Docker and Docker Compose
- kubectl and minikube (for Kubernetes)
- Terraform 1.6+
- AWS CLI (for infrastructure)

### 1. Clone and Setup

```bash
git clone <your-repo>
cd devsecops-nodejs-api

# Install dependencies
npm install

# Copy environment template
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

### 2. Local Development

```bash
# Run tests
npm test

# Start development server
npm run dev

# Security scans (local)
npm run security:audit
npm run security:sast
```

### 3. Docker Development

```bash
# Build secure container
docker build -t devsecops-api .

# Run with Docker Compose (includes monitoring)
docker-compose up -d

# View logs
docker-compose logs -f devsecops-app
```

### 4. Kubernetes Deployment

```bash
# Start minikube
minikube start

# Deploy application
kubectl apply -f k8s/

# Check deployment
kubectl get pods -n devsecops-app
kubectl get svc -n devsecops-app
```

## 🔒 Security Features

### Application Security (Dev)

- **Secure Coding**: Input validation, output encoding, error handling
- **Dependencies**: Automated vulnerability scanning with npm audit
- **Code Quality**: ESLint, Prettier, comprehensive test coverage
- **Security Headers**: Helmet.js for HTTP security headers
- **Rate Limiting**: Express rate limiter for DDoS protection

### Static Analysis (Sec)

- **SAST**: Semgrep for code vulnerability detection
- **SCA**: Trivy for dependency vulnerability scanning  
- **License**: Automated license compliance checking
- **Secrets**: Detection of hardcoded secrets in code

### Container Security

- **Multi-stage Build**: Minimal production image
- **Non-root User**: Application runs as unprivileged user
- **Read-only Filesystem**: Immutable container filesystem
- **No Privilege Escalation**: Security context restrictions
- **Health Checks**: Container health monitoring
- **Image Scanning**: Trivy container vulnerability scanning

### Infrastructure Security (Ops)

- **IaC Security**: Checkov and TFSec for Terraform scanning
- **Encryption**: S3 server-side encryption with AES-256
- **Access Control**: IAM least-privilege policies
- **Audit Logging**: CloudTrail for API call logging
- **Network Security**: VPC, security groups, NACLs

### Runtime Security

- **Pod Security Standards**: Kubernetes PSS enforcement
- **Network Policies**: Micro-segmentation with NetworkPolicy
- **RBAC**: Role-based access control
- **OPA Gatekeeper**: Policy enforcement at admission
- **Falco**: Runtime threat detection and alerting

## 📊 CI/CD Pipeline

Our GitHub Actions pipeline includes:

1. **Code Quality & SAST**
   - Unit tests with coverage
   - Semgrep static analysis
   - Code quality checks

2. **Dependency Scanning**
   - npm audit for Node.js dependencies
   - Trivy filesystem scanning
   - License compliance checks

3. **Infrastructure Scanning**
   - Terraform validation
   - Checkov policy scanning
   - TFSec security analysis

4. **Container Security**
   - Docker image building
   - Trivy container scanning
   - Container structure tests
   - Critical vulnerability blocking

5. **Deployment**
   - Automated deployment to dev/prod
   - Infrastructure provisioning
   - Application deployment

## 🛠️ Security Tools Integration

### Static Application Security Testing (SAST)
```bash
# Run Semgrep locally
semgrep --config=auto .

# Custom rules for Node.js
semgrep --config=p/nodejs --config=p/security-audit .
```

### Software Composition Analysis (SCA)
```bash
# Check for vulnerable dependencies
npm audit --audit-level high

# Trivy filesystem scan
trivy fs --security-checks vuln .
```

### Infrastructure as Code Security
```bash
# Checkov scan
checkov -d terraform/ --framework terraform

# TFSec scan
tfsec terraform/
```

### Container Security
```bash
# Build and scan
docker build -t devsecops-api .
trivy image devsecops-api

# Container structure test
container-structure-test test --image devsecops-api --config container-structure-test.yaml
```

## 🔐 Security Policies

### OPA Gatekeeper Policies

1. **RequireSecurityContext**: Ensures pods run with secure configurations
2. **DisallowPrivileged**: Prevents privileged container execution
3. **RequireResourceLimits**: Enforces resource constraints
4. **DisallowRoot**: Prevents containers from running as root

### Falco Runtime Rules

1. **Privilege Escalation**: Detects sudo/su usage
2. **Sensitive Files**: Monitors access to /etc, /passwd, etc.
3. **Network Anomalies**: Suspicious outbound connections
4. **Container Escape**: Detects escape attempts
5. **Reverse Shells**: Identifies shell spawning

## 📈 Monitoring & Alerting

### Metrics Collection
- **Prometheus**: Metrics scraping and storage
- **Grafana**: Dashboards and visualization
- **Node Exporter**: System metrics

### Log Management  
- **Fluentd**: Log collection and forwarding
- **Elasticsearch**: Log storage and indexing
- **Kibana**: Log analysis and search

### Security Monitoring
- **Falco**: Runtime security monitoring
- **OPA**: Policy violation alerts
- **CloudTrail**: AWS API audit logging

## 🏃‍♂️ Testing the Security

### 1. Vulnerability Testing
```bash
# Test with intentionally vulnerable dependencies
npm install express@4.16.0  # Old version with known CVE

# Run security scan - should fail
npm audit
```

### 2. Container Security Testing
```bash
# Try to run as root (should fail with policies)
docker run --rm --user root devsecops-api

# Test privilege escalation (should be blocked)
kubectl run test-pod --rm -it --image=devsecops-api -- /bin/bash
```

### 3. Runtime Security Testing
```bash
# Test Falco rules - attempt suspicious activity
kubectl exec -it deployment/devsecops-nodejs-api -- /bin/bash
# This should trigger "Shell Spawned in Container" alert

# Test network policy
kubectl run test-pod --rm -it --image=busybox -- wget http://devsecops-nodejs-api-svc
# Should be blocked by network policy

# Test OPA policies
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
          privileged: true  # Should be denied by OPA
EOF
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `production` |
| `PORT` | Application port | `3000` |
| `LOG_LEVEL` | Logging level | `info` |
| `REDIS_PASSWORD` | Redis password | `defaultpassword` |

### Terraform Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `aws_region` | AWS region | `string` | `us-west-2` |
| `environment` | Environment name | `string` | `dev` |
| `app_name` | Application name | `string` | `devsecops-nodejs-api` |
| `bucket_name` | S3 bucket base name | `string` | `devsecops-app-storage` |

## 🚨 Security Incident Response

### 1. High Severity Vulnerability Detected

```bash
# Stop affected services immediately
kubectl scale deployment devsecops-nodejs-api --replicas=0 -n devsecops-app

# Check for compromise indicators
kubectl logs deployment/devsecops-nodejs-api -n devsecops-app --tail=100

# Apply security patches
docker build -t devsecops-api:patched .
kubectl set image deployment/devsecops-nodejs-api app=devsecops-api:patched -n devsecops-app
```

### 2. Runtime Security Alert

```bash
# Check Falco alerts
docker-compose logs falco | grep -i "priority=CRITICAL"

# Investigate suspicious processes
kubectl exec -it deployment/devsecops-nodejs-api -- ps aux

# Network analysis
kubectl exec -it deployment/devsecops-nodejs-api -- netstat -tulpn
```

### 3. Policy Violation

```bash
# Check OPA Gatekeeper violations
kubectl get constraintviolations -A

# Review admission controller logs
kubectl logs -n gatekeeper-system deployment/gatekeeper-controller-manager
```

## 📋 Security Checklist

### Pre-deployment Security Review

- [ ] All dependencies scanned for vulnerabilities
- [ ] SAST scan passed with no critical findings
- [ ] Container security scan completed
- [ ] IaC security policies validated
- [ ] Secrets properly managed (no hardcoded secrets)
- [ ] Network policies configured
- [ ] RBAC permissions follow least privilege
- [ ] Resource limits configured
- [ ] Security context properly set
- [ ] Health checks implemented

### Production Security Requirements

- [ ] TLS encryption enabled
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Audit logging configured
- [ ] Monitoring alerts configured
- [ ] Incident response plan reviewed
- [ ] Security policies enforced
- [ ] Runtime security monitoring active
- [ ] Backup and recovery tested
- [ ] Access controls verified

## 🛡️ Security Controls Summary

### Preventive Controls
- **SAST/SCA**: Prevent vulnerable code from reaching production
- **IaC Security**: Secure infrastructure configuration
- **Container Security**: Hardened container images
- **Admission Controllers**: Policy enforcement at deployment

### Detective Controls  
- **Runtime Monitoring**: Falco for threat detection
- **Log Analysis**: Centralized logging and SIEM
- **Metrics Monitoring**: Anomaly detection
- **Vulnerability Scanning**: Continuous security assessment

### Responsive Controls
- **Automated Response**: Policy violations blocked automatically
- **Alerting**: Real-time security notifications
- **Incident Response**: Documented response procedures
- **Forensics**: Audit trails for investigation

## 🐛 Troubleshooting

### Common Issues

**1. Container fails to start**
```bash
# Check security context
kubectl describe pod <pod-name> -n devsecops-app

# Verify user permissions
docker run --rm devsecops-api id
```

**2. Policy violations blocking deployment**
```bash
# Check constraint violations
kubectl describe constraintviolation <violation-name>

# Review policy configuration
kubectl get constrainttemplates
```

**3. Network connectivity issues**
```bash
# Test network policy
kubectl run debug-pod --rm -it --image=busybox -- nslookup devsecops-nodejs-api-svc

# Check service endpoints
kubectl get endpoints -n devsecops-app
```

**4. Security scan failures**
```bash
# Review scan results
trivy image --format json devsecops-api | jq '.Results[].Vulnerabilities[] | select(.Severity == "CRITICAL")'

# Update dependencies
npm audit fix
```


---

## 🎯 Security Objectives Achieved

✅ **Application Security**: Secure coding practices, input validation, security headers  
✅ **Code Security**: SAST scanning, dependency management, secret detection  
✅ **Container Security**: Hardened images, non-root user, security contexts  
✅ **Infrastructure Security**: IaC scanning, encryption, access controls  
✅ **Runtime Security**: Policy enforcement, threat detection, monitoring  
✅ **CI/CD Security**: Automated scanning, security gates, compliance checks  

This project demonstrates a comprehensive DevSecOps implementation with security integrated at every stage of the software development lifecycle.