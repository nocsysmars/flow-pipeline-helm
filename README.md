# Flow-pipeline Helm Charts

- install flow-pipeline on k8s.

## Usage:

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

```console
git clone https://github.com/SquidRo/helm-flow-pipe
cd helm-flow-pipe
helm install {release} -n {namespace} .
```

{release} is a string name

grafana default account/password is admin/grafana. If you want to change it, please refer to values.yaml

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

