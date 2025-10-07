# 🚀 Open WebUI + Ollama on Azure AKS (with Llama 2)

This project demonstrates a cloud-native deployment of Open WebUI connected to Ollama running a lightweight Llama 2 model, all on Azure Kubernetes Service (AKS) using Terraform.

**Goal:** Deploy an end-to-end AI chat interface on the cloud, make it accessible, and ensure it responds using an actual model.

---

## 🧩 Architecture Overview

```
Terraform ──► Azure AKS Cluster ──► Kubernetes Deployments
                        │
                        ├── Ollama Pod  →  Llama 2 model (pulled inside)
                        │
                        └── Open WebUI Service (LoadBalancer → Public IP)
```

- Modular, scalable, and cloud-native.

---

## 🧰 Prerequisites

- **Azure Subscription** (Pay-As-You-Go, with budget alerts)
- **Service Principal** (SPN) with Contributor rights
- **Locally stored Client ID & Secret** for Terraform
- **Installed Tools:**
  - [Terraform](https://www.terraform.io/downloads.html)
  - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/)
  - Docker (optional, for local testing)

> **Tip:** Ensure `az login` works and your SPN is correctly configured.

---

## ⚙️ Infrastructure Deployment (Terraform on Azure)

All configuration is in the `terraform/` directory.

**Steps:**
```sh
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

After provisioning, configure `kubectl`:
```sh
az aks get-credentials --resource-group aks-demo-rg --name my-aks-cluster
kubectl get nodes
```

---

## 🧱 Application Deployment (Kubernetes Manifests)

Deploy the app stack:
```sh
kubectl apply -f k8s/deploy.yaml
```

This creates:
- Open WebUI Pod
- Ollama Pod
- LoadBalancer Service exposing Open WebUI

**Verify:**
```sh
kubectl get pods
kubectl get svc
kubectl get service open-webui-service --watch
```

---

## 🧠 Model Setup (Inside the Ollama Pod)

Ollama requires manual model download.

**Find the pod:**
```sh
kubectl get pods
```

**Enter the pod:**
```sh
kubectl exec -it <ollama-pod-name> -- bash
```

**Pull Llama 2:**
```sh
ollama pull llama2
```

---

## 🌍 Accessing Open WebUI

Once the service has an external IP:
```
http://<EXTERNAL-IP>:8080
```
Open in your browser, link to Ollama backend, and chat with Llama 2.

---

## 🔍 Challenges and Solutions

1. **Local Resource Limits:** Upgraded VM resources to avoid freezes.
2. **Missing Model in WebUI:** Pulled `llama2` manually inside Ollama pod.
3. **Azure Cost Management:** Set up budget and alerts.
4. **Documentation Overload:** Validated each step, avoided copy-paste errors.

---

## 🧹 Cleanup

To destroy all resources and avoid charges:
```sh
terraform destroy -auto-approve
```

---

## 🧾 Assumptions & Known Limitations

- Used LoadBalancer (not Ingress) for simplicity.
- No persistent volume for Ollama model storage (model redownloads on pod restart).
- Tested with Llama 2 only.
- Default Azure node pool (no GPU).

---

## ⚡ Optional Automation Script

See [`setup.sh`](setup.sh) for a helper script that:
- Runs Terraform
- Applies K8s manifests
- Fetches the external IP for WebUI

---

## 🎥 Demo Links

- **Live Deployment:** [Add your public endpoint here]
- **GitHub Repo:** [Add repo URL]
- **Video Walkthrough:** [Add YouTube or Drive link]

---

## 💭 Final Thoughts

This project was a technical assessment that became a deep dive into cloud automation, Kubernetes networking, and model orchestration. Deploying an AI model end-to-end on a real cloud cluster was deeply satisfying.

---
