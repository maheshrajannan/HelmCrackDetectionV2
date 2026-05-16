(1) Creating Cluster in terraform


```
cd terraform
terraform apply -auto-approve
```

(2) Running all helm charts

-> Go to /root directory and then run the runHelmCharts.sh

```
sh runHelmCharts.sh
```

-> That's it, we'll get all 3 apps up and running there IP as well.


<!-- (3) Creating masterChart

-> Installing 4 child chart inside this masterChart 
   
   1) pv-chart
   2) image-upload
   3) crack-detection
   4) concrete-image-gallery

```
helm upgrade --install master-chart ./masterChart
```


kubectl get service/image-upload-svc-lb --watch

kubectl get service/concrete-image-gallery-svc-lb --watch -->