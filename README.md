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
    - name: deploy to cluster
      uses: josuelopezv/K8AppDeploy@main
      with: # defaults to latest kubectl binary version
        config: ${{ secrets.KUBE_CONFIG_DATA }}
        command: set image --record deployment/my-app container=${{ github.repository }}:${{ github.sha }}
```

## Arguments

`command` – **required**: The command you want to run, without `kubectl`, e.g. `get pods`

`config` – **required**: A base64-encoded kubeconfig file with credentials for Kubernetes to access the cluster. You can get it by running the following command:

```bash
cat $HOME/.kube/config | base64
```