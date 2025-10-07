#!/bin/bash
echo "🚀 Applying Kubernetes manifests..."
kubectl apply -f deployment.yaml

echo "⏳ Waiting for Ollama pod to be ready..."
kubectl wait --for=condition=ready pod -l app=ollama --timeout=300s

OLLAMA_POD=$(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}')
echo "📥 Pulling llama2 model into pod: $OLLAMA_POD..."
kubectl exec -it $OLLAMA_POD -- ollama pull llama2

echo "🌐 Waiting for public IP for WebUI..."
kubectl wait --for=condition=ready pod -l app=open-webui --timeout=300s
kubectl get service open-webui-service

echo "🔗 Configuring Application Gateway backend pool..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
#Update the backend pool with the external IP from the ingress-nginx service
echo "✅ Deployment complete! Find your public IP above."
