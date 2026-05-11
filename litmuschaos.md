kubectl create ns litmus

helm upgrade --install litmus litmuschaos/litmus -n litmus --set portal.server.resources.requests.cpu=100m --set portal.server.resources.requests.memory=256Mi

helm upgrade --install litmus litmuschaos/litmus --namespace litmus --set portal.frontend.service.type=LoadBalancer --set portal.server.service.type=LoadBalancer

kubectl apply -f https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/3.21.0/litmus-portal-crds.yml

kubectl apply -f Downloads/crack-detection-litmus-chaos-enable.yml
