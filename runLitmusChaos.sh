#!/bin/bash
set -e

echo "======================================================"
echo "          LitmusChaos Test Automation Script          "
echo "======================================================"

read -p "Do you want to run the LitmusChaos test? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborting LitmusChaos automation."
    exit 0
fi

echo "Proceeding with LitmusChaos installation..."

echo "Creating 'litmus' namespace..."
kubectl create ns litmus || true

echo "Adding Litmus Chaos Helm Repository..."
helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/ || true
helm repo update

echo "Installing Litmus Chaos Portal via Helm..."
helm upgrade --install litmus litmuschaos/litmus -n litmus \
    --set portal.server.resources.requests.cpu=100m \
    --set portal.server.resources.requests.memory=256Mi

helm upgrade --install litmus litmuschaos/litmus --namespace litmus \
    --set portal.frontend.service.type=LoadBalancer \
    --set portal.server.service.type=LoadBalancer

echo "Applying Litmus Portal CRDs..."
kubectl apply -f https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/3.21.0/litmus-portal-crds.yml

