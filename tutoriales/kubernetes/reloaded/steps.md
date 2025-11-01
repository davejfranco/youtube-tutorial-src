## Reloaded

### Requisitos
- k8s cluster (kind o cualquier otro)
- kubectl
- helm

### Steps

***Create cluster*** 

```bash
kind create cluster -f kind.yaml
```

***Install***

```bash
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update 
kubectl create namespace reloader
helm install reloader stakater/reloader --namespace reloader
```

***Deploy sample app***
```bash
kubectl apply -f configmap.yaml 

kubectl apply -f deployment.yaml

```


***port-forwad app***
```
k port-forward deploy/web 8080:80
```

***Aplicar annotation al deployment***

```
  template:
    metadata:
      labels:
        app: web
      #annotations:
      #  reloader.stakater.com/auto: "true"
```

***Modificar configmap***
```

apiVersion: v1
kind: ConfigMap
metadata:
  name: web-nginx-conf
  namespace: default
data:
  nginx.conf: |
    user  nginx;
    worker_processes  1;

    events { worker_connections 1024; }

    http {
      server {
        listen 80;
        location / {
          add_header X-Message "v2";
          return 200 "Hello from nginx (v2)\n";
        }
      }
    }
```

```bash
kubectl apply -f configmap.yaml
```

Puedes mirar como los pods del deployment se refrescan y automaticamente queda refrescado la nueva version
