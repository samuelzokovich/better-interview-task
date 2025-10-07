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

echo "✅ Deployment complete! Find your public IP above."
