# K8AppDeploy
Deploy Docker App to Kubernetes Cluster

## Usage

`.github/workflows/push.yml`

```yaml
on: push
name: deploy
jobs:
  deploy:
    name: deploy to cluster
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Deploy to Kubernetes cluster
      uses: josuelopezv/K8AppDeploy@main
      with:
        kube-config: ${{ secrets.KUBE_CONFIG_DATA}}
        container-image: nginx:latest
        app-name: my-app
        app-namespace: app-example
        ingress-hostname: example.agileliteracy.com
        app-port: 80
        ingress-extra-annotations: |
          nginx.ingress.kubernetes.io/proxy-buffering: "on",
          nginx.ingress.kubernetes.io/server-snippet: 
            "proxy_cache mycache;
             proxy_cache_lock on;
             proxy_cache_valid any 60m;
             proxy_ignore_headers Cache-Control;"
        extra-cmd: |
          kubectl get pods -A
          echo "completed"
```

## Arguments

`kube-config` – **required**: A base64-encoded kubeconfig file with credentials for Kubernetes to access the cluster. You can get it by running the following command:
```bash
cat $HOME/.kube/config | base64
```
`container-image` – **required**: The container image to pull in kubernetes. Can use private registry for example repo.example.com/nginix:latest

`app-name` – **required**: Name to be used for kubernetes resources: service, deploy, pod, ingress

`app-namespace` – **required**: Namespace to be used generated and used for kubernetes resources: service, deploy, pod, ingress

`app-port` – **required**: Container port exposed by image to use as source for ingress reverse proxy

`ingress-hostname` – **required**: Ingress host. For example app.mydomain.com

`ingress-path` – : Ingress path used for backend and frontend. Default value: ```/```. See https://kubernetes.io/docs/concepts/services-networking/ingress/

`ingress-extra-annotations` – : Additional annotations for the ingress. String separated by coma. See some nginx specific ingrees annotations https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations 

`extra-cmd` – : extra bash commands to run after deploy

