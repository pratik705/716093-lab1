# Ingress-Nginx

Ingress-Nginx deploys an ingress controller, enabling the creation of Ingress resources.

It is deployed in the `rackspace-system` namespace, providing the necessary infrastructure for users to create Ingress resources. Additionally, it creates the `rackspace-nginx` Ingress class.

For any changes or customization, modify the `values.yaml` file or create Kubernetes manifest file.