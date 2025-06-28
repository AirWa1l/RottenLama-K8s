#!/bin/bash

# Script para desplegar Canary Deployment en Kubernetes

# Crear secretos - Reemplazar con los valores correctos 
kubectl create secret generic rottenlama-secrets --from-literal=database_url='postgresql://user:password@db-host:5432/rottenlama'

# Desplegar backend estable
kubectl apply -f backend/deployment-stable.yaml
kubectl apply -f backend/service.yaml

# Desplegar frontend estable
kubectl apply -f frontend/deployment-stable.yaml
kubectl apply -f frontend/service.yaml

# Desplegar ingress
kubectl apply -f ingress.yaml

echo "Despliegue estable completado. Ahora desplegando versión canary..."

# Desplegar versión canary (con 20% del tráfico)
kubectl apply -f backend/deployment-canary.yaml
kubectl apply -f frontend/deployment-canary.yaml

echo "Canary Deployment completado. 20% del tráfico ahora va a la versión canary."