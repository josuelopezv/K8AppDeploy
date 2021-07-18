#!/bin/sh -l

set -e
KUBE_CONFIG_DATA=$1
IMG_TAG=$2
APP_NAME=$3
APPNS=$4
APP-PORT=$5
HOST_NAME=$6
APP_PATH=$7
EXTRA_ANNOTATIONS=$8
USE_CACHE=$9

version=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -sLO "https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl" -o kubectl
chmod +x kubectl
mkdir -p ~/.local/bin/kubectl
mv ./kubectl ~/.local/bin/kubectl
PATH=$PATH:~/.local/bin/kubectl
echo "$KUBE_CONFIG_DATA" | base64 -d > /tmp/config
export KUBECONFIG=/tmp/config

if ["$USE_CACHE" = true]; then
CACHE_ANNOTATIONS=$(cat <<EOF
kubernetes.io/ingress.class: nginx
nginx.ingress.kubernetes.io/proxy-buffering: "on",
nginx.ingress.kubernetes.io/server-snippet: "
    proxy_cache mycache;
    proxy_cache_lock on;
    proxy_cache_valid any 60m;
    proxy_ignore_headers Cache-Control;
    add_header X-Cache-Status $upstream_cache_status;
"
EOF
)

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app: ingress-nginx
  name: nginx-configuration
  namespace: ingress-nginx
data:
  http-snippet: "proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=defaultcache:200m use_temp_path=off max_size=4g inactive=24h;"
EOF
fi

if [  "$APPNS" != "default" ] ; then
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
    name: $APPNS
EOF
fi

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Service
metadata:
    name: $APP_NAME
    namespace: $APPNS
spec:
    selector:
    app: $APP_NAME
    ports:
    - protocol: TCP
        port: $APP-PORT
        targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: $APP_NAME
    namespace: $APPNS
    labels:
    app: $APP_NAME
spec:
    replicas: 1
    selector:
    matchLabels:
        app: $APP_NAME
    template:
    metadata:
        labels:
        app: $APP_NAME
    spec:
        containers:
        - name: $APP_NAME
        image: $IMG_TAG
        ports:
        - containerPort: $APP-PORT    
---
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: $APP_NAME
    namespace: $APPNS
    annotations:
    {
        $EXTRA_ANNOTATIONS, $CACHE_ANNOTATIONS
    }
spec:
    rules:
    - host: $HOST_NAME
    http:
        paths:
        - path: $APP_PATH
        pathType: ImplementationSpecific
        backend:
            service:
            name: $APP_NAME
            port:
                number: 80
EOF

kubectl set image deployment/$APP_NAME $APP_NAME=$IMG_TAG --record -n $APPNS
kubectl rollout restart deployment/$APP_NAME -n $APPNS