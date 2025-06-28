# RottenLama K8s - Canary Deployment

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)

Este repositorio implementa una **estrategia de Canary Deployment** para la aplicación RottenLama utilizando Kubernetes, permitiendo despliegues seguros y gradual rollout de nuevas versiones.

## 📋 Tabla de Contenidos

- [¿Qué es Canary Deployment?](#-qué-es-canary-deployment)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Configuración](#-configuración)
- [Despliegue](#-despliegue)
- [Monitoreo](#-monitoreo)
- [Rollback](#-rollback)
- [Ventajas](#-ventajas)

## 🐦 ¿Qué es Canary Deployment?

Un **Canary Deployment** es una estrategia de despliegue que reduce el riesgo de introducir nuevas versiones al dirigir solo un pequeño porcentaje del tráfico hacia la nueva versión (canary) mientras la mayoría del tráfico sigue yendo a la versión estable.

### Flujo del Canary Deployment:
1. **Versión Estable** (75%) - Versión actual en producción
2. **Versión Canary** (25%) - Nueva versión con funcionalidades actualizadas
3. **Monitoreo** - Observación de métricas y comportamiento
4. **Decisión** - Promoción completa o rollback

## 🏗️ Arquitectura

```
┌─────────────────┐
│   Ingress       │ ← Punto de entrada (20% canary weight)
│  (nginx)        │
└─────────┬───────┘
          │
    ┌─────▼─────┐
    │  Service  │ ← Distribuye tráfico
    └─────┬─────┘
          │
    ┌─────▼─────┬─────────────┐
    │           │             │
┌───▼───┐   ┌───▼───┐    ┌────▼────┐
│Stable │   │Stable │    │ Canary  │
│ Pod   │   │ Pod   │    │  Pod    │
│ (33%) │   │ (33%) │    │  (33%)  │
└───────┘   └───────┘    └─────────┘
```

## 📁 Estructura del Proyecto

```
RottenLama-K8s/
├── deploy-canary.sh          # Script de despliegue automatizado
├── ingress.yaml              # Configuración de Ingress con canary
├── backend/
│   ├── deployment-stable.yaml    # Backend estable (3 réplicas)
│   ├── deployment-canary.yaml    # Backend canary (1 réplica)
│   └── service.yaml              # Servicio compartido del backend
└── frontend/
    ├── deployment-stable.yaml    # Frontend estable (3 réplicas)
    ├── deployment-canary.yaml    # Frontend canary (1 réplica)
    └── service.yaml              # Servicio compartido del frontend
```

## ⚙️ Configuración

### Características Clave:

#### 1. **Deployments Duales**
- **Versión Estable**: 3 réplicas por servicio
- **Versión Canary**: 1 réplica por servicio
- **Imágenes Diferentes**: 
  - Stable: `airwa1l/rottenlama-backend:stable`
  - Canary: `airwa1l/rottenlama-backend:canary`

#### 2. **Distribución de Tráfico**
```yaml
# Ingress Configuration
annotations:
  nginx.ingress.kubernetes.io/canary: "true"
  nginx.ingress.kubernetes.io/canary-weight: "20"
```

#### 3. **Etiquetado por Versiones**
```yaml
# Stable Deployment
labels:
  app: rottenlama-backend
  version: stable

# Canary Deployment  
labels:
  app: rottenlama-backend
  version: canary
```

#### 4. **Recursos y Health Checks**
- **CPU**: 0.2-0.5 cores
- **Memoria**: 256Mi-512Mi
- **Liveness Probes**: Configurados para ambas versiones
- **Readiness**: Verificación de salud antes de recibir tráfico

## 🚀 Despliegue

### Prerrequisitos:
- Cluster de Kubernetes funcionando
- kubectl configurado
- NGINX Ingress Controller instalado

### Despliegue Automático:
```bash
# Ejecutar el script de despliegue
chmod +x deploy-canary.sh
./deploy-canary.sh
```

### Despliegue Manual:

1. **Crear secretos**:
```bash
kubectl create secret generic rottenlama-secrets \
  --from-literal=database_url='postgresql://user:password@db-host:5432/rottenlama'
```

2. **Desplegar versión estable**:
```bash
kubectl apply -f backend/deployment-stable.yaml
kubectl apply -f backend/service.yaml
kubectl apply -f frontend/deployment-stable.yaml
kubectl apply -f frontend/service.yaml
```

3. **Configurar Ingress**:
```bash
kubectl apply -f ingress.yaml
```

4. **Desplegar versión canary**:
```bash
kubectl apply -f backend/deployment-canary.yaml
kubectl apply -f frontend/deployment-canary.yaml
```

## 📊 Monitoreo

### Verificar el estado del despliegue:
```bash
# Ver todos los pods
kubectl get pods -l app=rottenlama-backend
kubectl get pods -l app=rottenlama-frontend

# Ver servicios
kubectl get services

# Ver ingress
kubectl get ingress

# Logs de la versión canary
kubectl logs -l version=canary
```

### Métricas a monitorear:
- **Tasa de error** (Error rate)
- **Latencia** (Response time)
- **Throughput** (Requests per second)
- **Recursos** (CPU/Memory usage)
- **Health checks** status

## 🔄 Rollback

### Rollback de emergencia:
```bash
# Eliminar deployments canary
kubectl delete deployment rottenlama-backend-canary
kubectl delete deployment rottenlama-frontend-canary
```

### Promoción completa (si todo va bien):
```bash
# Escalar canary a más réplicas
kubectl scale deployment rottenlama-backend-canary --replicas=3
kubectl scale deployment rottenlama-frontend-canary --replicas=3

# Reducir versión estable
kubectl scale deployment rottenlama-backend-stable --replicas=0
kubectl scale deployment rottenlama-frontend-stable --replicas=0
```

## ✅ Ventajas

### 🛡️ **Reducción de Riesgo**
- Solo 20-25% del tráfico expuesto a la nueva versión
- Detección temprana de problemas
- Impacto limitado en usuarios

### 🚀 **Despliegue Gradual**
- Rollout controlado y medido
- Tiempo para evaluar métricas
- Confianza progresiva en la nueva versión

### 🔧 **Flexibilidad**
- Fácil rollback en caso de problemas
- Ajuste dinámico de porcentajes de tráfico
- Configuración por servicio

### 📈 **Observabilidad**
- Comparación directa entre versiones
- Métricas en tiempo real
- Validación con tráfico real

## 🎯 Casos de Uso Ideales

- **Aplicaciones críticas** que requieren alta disponibilidad
- **Nuevas funcionalidades** que necesitan validación
- **Cambios de arquitectura** que pueden afectar rendimiento
- **Actualizaciones de seguridad** que requieren verificación

## 🔧 Personalización

Para ajustar el porcentaje de tráfico canary, modificar en `ingress.yaml`:
```yaml
annotations:
  nginx.ingress.kubernetes.io/canary-weight: "20"  # Cambiar este valor (0-100)
```

Para diferentes ratios de réplicas, ajustar en los archivos de deployment:
```yaml
spec:
  replicas: 3  # Ajustar según necesidades
```

