
# Distributed Resilience Demo (Kubernetes)

Demo para charla **"Distributed Resilience: Cómo diseñar sistemas que no fallan (aunque todo lo demás sí)"**.

## Objetivo
Mostrar resiliencia y *cost-aware design* con:
- Blue/Green conmutado vía `Service` selector
- HPA (Horizontal Pod Autoscaler) por despliegue
- Simulación de fallos (delete pods)
- Estimaciones simples de costos (FinOps mindset)

## Requisitos
- macOS con Docker, kubectl, y minikube
- Python 3.11+
- `curl`

## Pasos rápidos

```bash
# 1) Iniciar y desplegar
./scripts/deploy.sh

# 2) Abrir la URL
minikube service web -n distributed-resilience --url

# 3) Enviar carga (autoescalado)
./scripts/load-test.sh

# 4) Simular fallo en 'blue' (pods caen y se regeneran)
./scripts/simulate-failure.sh blue

# 5) Conmutar manualmente a 'green' (failover)
./scripts/switch.sh green
```

> Consejo: observá `kubectl -n distributed-resilience get hpa,pods -w` en otra terminal.

## Cost Management (ilustrativo)
Editá `cost/cost_assumptions.md` y ejecutá:
```bash
python cost/calc_costs.py
```

## Extensión a cloud público
- Publicá la imagen en un registry (GHCR, ECR, IBM CR)
- Desplegá en 2 regiones (us-east / us-west) con el mismo `Service`/Ingress
- Observá costos con Kubecost o Cost Explorer
- Automatizá con GitHub Actions

## Limpieza
```bash
kubectl delete ns distributed-resilience
# o
minikube delete
```
