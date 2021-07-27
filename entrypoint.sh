#!/bin/sh

set -e
KUBE_CONFIG_DATA=$1
IMG_TAG=$2
APP_NAME=$3
APPNS=$4
APP_PORT=$5
HOST_NAME=$6
APP_PATH=$7
EXTRA_ANNOTATIONS=$8
EXTRA_CMDS=$9
EXTRA_ENV=${10}

echo "downloading kubectl"
version=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -sLO "https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl" -o kubectl
chmod +x kubectl
mkdir -p ~/.local/bin/kubectl
mv ./kubectl ~/.local/bin/kubectl
PATH=$PATH:~/.local/bin/kubectl
echo "$KUBE_CONFIG_DATA" | base64 -d > /tmp/config
export KUBECONFIG=/tmp/config
echo "kubectl $version config completed"

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
      port: $APP_PORT
      targetPort: 80
---
EOF

cat <<EOF | kubectl apply -f -
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
          imagePullPolicy: Always
          env: [ $EXTRA_ENV ]
          ports:
          - containerPort: $APP_PORT    
---
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: $APP_NAME
    namespace: $APPNS
    annotations: { $EXTRA_ANNOTATIONS }
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
echo "applied config files"
kubectl set image deployment/$APP_NAME $APP_NAME=$IMG_TAG --record -n $APPNS
kubectl rollout restart deployment/$APP_NAME -n $APPNS
kubectl rollout status deployment/$APP_NAME -n $APPNS
set +e
if ! [ -z "$EXTRA_CMDS" ] ; then sh -c "$EXTRA_CMDS"; fi
echo "Successful deployed to $HOST_NAME$APP_PATH"
exit 0