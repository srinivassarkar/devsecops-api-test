
---

# 🚀 DevSecOps API — Project Setup Guide

This guide explains how to build, run, and deploy the **DevSecOps API** locally and in Kubernetes.

---

## 📋 Prerequisites

Make sure you have the following installed:

* **Git** ≥ 2.25
* **Docker** ≥ 20.10
* **Node.js** ≥ 18.x (only if running locally outside Docker)
* **Minikube** ≥ 1.30 (for local Kubernetes)
* **kubectl** ≥ 1.27
* **Helm** (if charts are provided)
* **Trivy** (optional, for vulnerability scanning)

You also need:

* A [Docker Hub](https://hub.docker.com/) account (or another container registry).

---

## ⚙️ 1. Clone the Repository

```bash
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
```

---

## 🐳 2. Build and Run with Docker

### Build Image

```bash
docker build -t devsecops-api:1.0.0 .
```

### Run Container

```bash
docker run -p 3000:3000 devsecops-api:1.0.0
```

API will be available at:
👉 [http://localhost:3000](http://localhost:3000)

---

## 📦 3. Push Image to Docker Hub

```bash
# Tag the image
docker tag devsecops-api:1.0.0 <your-dockerhub-username>/devsecops-api:1.0.0

# Login
docker login

# Push
docker push <your-dockerhub-username>/devsecops-api:1.0.0
```

---

## ☸️ 4. Deploy to Minikube (Local Kubernetes)

1. Start Minikube:

   ```bash
   minikube start
   ```

2. Apply Kubernetes manifests:

   ```bash
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   ```

3. Verify pods:

   ```bash
   kubectl get pods
   ```

4. Access API via NodePort:

   ```bash
   minikube service devsecops-api-service
   ```

---

## 🔒 5. Security Scanning (Optional)

Run **Trivy** on the image:

```bash
trivy image <your-dockerhub-username>/devsecops-api:1.0.0
```

---

## ⚡ 6. CI/CD Pipeline

* GitHub Actions is configured for:

  * **Build & Test** (Node.js + Jest)
  * **Docker Build & Push**
  * **Trivy Security Scan**
  * **Deployment (optional, if configured)**

All workflows are in `.github/workflows/`.

---

## 📑 API Documentation

* Health check:

  ```bash
  curl http://localhost:3000/health
  ```

  Response:

  ```json
  { "status": "ok" }
  ```

* Other endpoints are defined in `server.js`.

---

## 👤 Maintainer

* **Name**: Your Team
* **Email**: [devsecops@example.com](mailto:devsecops@example.com)

---

⚠️ **Note for Client:**
This project is designed as a **DevSecOps demo**. The pipeline includes vulnerability scanning, containerization, and Kubernetes deployment for demonstration purposes. For production, adjust vulnerability policies and cloud registry integration.

---

Would you like me to also prepare a **`docs/INSTALL.md`** (step-by-step installation manual for non-technical users) or is this single README enough for your client handover?
