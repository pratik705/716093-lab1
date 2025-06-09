#!/bin/bash

if [ -d "charts" ]; then
    echo "Removing existing 'charts/' directory to force Helm chart re-rendering..."
    rm -rf charts
fi

RENDERED_MANIFEST=$(mktemp)
kustomize build --enable-helm=true . > "$RENDERED_MANIFEST"

echo "Checking for completed jobs in rendered manifests..."
awk '/^kind: Job$/ {job=1} job && /^  name:/ {name=$2} job && /^  namespace:/ {ns=$2; print name, ns; job=0} job && /^metadata:/ {ns="default"}' "$RENDERED_MANIFEST" | while read JOB_NAME JOB_NAMESPACE; do
    JOB_NAMESPACE=${JOB_NAMESPACE:-default}
    STATUS=$(kubectl get job "$JOB_NAME" -n "$JOB_NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null || true)
    if [ "$STATUS" == "True" ]; then
        echo "Deleting completed Job: $JOB_NAME in namespace: $JOB_NAMESPACE"
        kubectl delete job "$JOB_NAME" -n "$JOB_NAMESPACE"
    fi
done

while true; do
    kubectl apply -f "$RENDERED_MANIFEST"
    if [ $? -eq 0 ]; then
        echo "All resources installed successfully."
        break
    else
        echo "Retrying in 5 seconds..."
        sleep 5
    fi
done

while true; do
    kustomize build --enable-helm=true gateway-api/ | kubectl apply --server-side=true -f -
    if [ $? -eq 0 ]; then
        echo "All resources installed successfully."
        break
    else
        echo "Retrying in 5 seconds..."
        sleep 5
    fi
done

rm "$RENDERED_MANIFEST"