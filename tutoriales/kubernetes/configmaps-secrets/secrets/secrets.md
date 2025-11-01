### Secrets
En Kubernetes, un Secret es un objeto similar a un ConfigMap, pero diseñado para almacenar información sensible o confidencial como:

contraseñas,

tokens de API,

claves privadas,

certificados TLS, etc.

A diferencia de los ConfigMaps, los Secrets se almacenan en base64 dentro del clúster, y Kubernetes intenta protegerlos de varias formas:

No se imprimen directamente en texto plano.

Se pueden restringir por permisos RBAC.

Algunos tipos de Secrets (como kubernetes.io/tls) están especialmente diseñados para integrarse con componentes del sistema.


### Tipos de secrets 
Built-in Type                         | Usage
Opaque                                | arbitrary user-defined data
kubernetes.io/service-account-token   | ServiceAccount token
kubernetes.io/dockercfg               | serialized ~/.dockercfg file
kubernetes.io/dockerconfigjson        | serialized ~/.docker/config.json file
kubernetes.io/basic-auth              | credentials for basic authentication
kubernetes.io/ssh-auth                | credentials for SSH authentication
kubernetes.io/tls                     | data for a TLS client or server
bootstrap.kubernetes.io/token         | bootstrap token data


***Opaque***
Los secrets necesitan ser creados y encoded en base64

```bash
echo admin | base64
```

***ServiceAccount token Secrets***

Esto es un mecanismo legado para tokens de service account, en versiones post 1.22 lo que se hace 
es generar un token que dura temporalmente y que se va rotando

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-sa-sample
  annotations:
    kubernetes.io/service-account.name: "sa-name"
type: kubernetes.io/service-account-token
data:
  extra: YmFyCg==
```

***Docker Secrets***

Hay dos maneras de guardar credenciales de docker 

- `kubernetes.io/dockercfg` 

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-dockercfg
type: kubernetes.io/dockercfg
data:
  .dockercfg: |
    eyJhdXRocyI6eyJodHRwczovL2V4YW1wbGUvdjEvIjp7ImF1dGgiOiJvcGVuc2VzYW1lIn19fQo=
```

- `kubernetes.io/dockerconfigjson` Este almacena en el mismo formato de `~/.docker/config.json`

```bash
kubectl create secret docker-registry secret-tiger-docker \
  --docker-email=tiger@acme.example \
  --docker-username=tiger \
  --docker-password=pass1234 \
  --docker-server=my-registry.example:5000
```

***SSH Secrets***
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-ssh-auth
type: kubernetes.io/ssh-auth
data:
  # the data is abbreviated in this example
  ssh-privatekey: |
    UG91cmluZzYlRW1vdGljb24lU2N1YmE=
```
***TLS Secrets***
Se usa mucho este para comunicaciones seguras

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-tls
type: kubernetes.io/tls
data:
  # values are base64 encoded, which obscures them but does NOT provide
  # any useful level of confidentiality
  # Replace the following values with your own base64-encoded certificate and key.
  tls.crt: "REPLACE_WITH_BASE64_CERT" 
  tls.key: "REPLACE_WITH_BASE64_KEY"
```
***Bootstrap token secrets***

Se utiliza durante el proceso en el que un nuevo nodo se va unir al cluster

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-tls
type: kubernetes.io/tls
data:
  # values are base64 encoded, which obscures them but does NOT provide
  # any useful level of confidentiality
  # Replace the following values with your own base64-encoded certificate and key.
  tls.crt: "REPLACE_WITH_BASE64_CERT" 
  tls.key: "REPLACE_WITH_BASE64_KEY"
```



