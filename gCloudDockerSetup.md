# Pre-Requisites for gCloud & Docker Setup

### Docker

1. Let us install [docker](https://docs.docker.com/engine/install/).If you are mac user please follow [this](https://docs.docker.com/desktop/mac/install/).

2. Let us now create account on [DockerHub](https://hub.docker.com/).

![DockerHub Login](/docScreenshots/loginDockerHub.png)

3. For mac OR windows please install `docker desktop` then run & start the `docker engine`.

4. If you have linux then you just have to install docker then turn on docker engine.

5. Ensure docker is installed as per below image.

![Docker Version](docScreenshots/dockerVersion.png)

### Installing gCloud

1. On google [cloud](https://cloud.google.com) create account and navigate to console.

![gCloud Login](/docScreenshots/loginGcloud.png)

2. Let us add `credit card` when we login.

3. Credit card will not be charged as long as we are staying with in the `free tier`. we will delete the cluster as soon as we are done, so no issues.

4. Please click on `Go to console` button. Notice the `My first project` on left upper side corner. This is shown in the screenshot below.

![GCP First Project](/docScreenshots/gcloudFirstProject.jpg)

5. Please set up `billing account` look at the screenshot below.

![Billing](/docScreenshots/billing.png)

**gCloud SDK**

1. Please install gCloud [SDK](https://cloud.google.com/sdk/docs/install).

2. In below image please select your OS.

![Installing Gcloud SDK](/docScreenshots/installGcloudSDK.png)

3. Install it and check the version like below.


![Gcloud Version](/docScreenshots/gCloudVersion.png)

4. Ensure that gcloud directory is included in the path variable.

5. Enter the `gcloud auth login` to authenticate to GCP.

```
gcloud auth login
```

5.b AFter login, ensure you can see the pods.

```
Maheshs-MacBook-Pro-3:keys maheshrajannan$ kubectl get pods
NAME                                           READY   STATUS    RESTARTS   AGE
concrete-image-gallery-depl-65f4f7464c-mghkg   1/1     Running   0          52m
crack-detection-depl-69fc67785d-ht7hl          1/1     Running   0          52m
image-upload-depl-5cc7848856-tmrtl             1/1     Running   0          52m
nfs-server-depl-9dcc654bb-22rfc                1/1     Running   0          52m

```

6. This command will open another browser and ask permission. This will wire the gcloud permission from UI to our local shell.

7. This command will initialize the gcloud CLI.

```
gcloud init
```
![Gcloud Init](/docScreenshots/gcloudInit.png)


8. Click on `top-left main menu symbol` then scroll. As shown in the image below,

![MenuPage](/docScreenshots/menuPage.png)

9. Please use `compute engine` so you can click on compute engine then you will get option for `Enable the API`.

![Enable Compute engine api](/docScreenshots/enableComputeEngineAPI.jpg)

10. Also enable `kubernetes engine API`.

![Enable Kubernetes engine API](/docScreenshots/enableK8sEngineAPI.png)

### Creating Service Account

We have create a new project then there is by default Compute Engine default service account available after then we have to create a new service account with 5 roles which is mentioned below.

1) Compute Engine Service Agent
2) Kubernetes Engine Service Agent
3) Container Registry Service Agent

After then create the json key then add it in the main.tf and also change the project name as per your project name.

<!-- 
```

These ones do not work.
#TODO: fix it.

gcloud iam service-accounts create helm-sa-1 --display-name "Helm Service Account"


gcloud projects add-iam-policy-binding concrete-detection-2 \
    --member "serviceAccount:helm-sa@concrete-detection-2-iam.gserviceaccount.com" \
    --role "roles/kubernetes.serviceAgent"

gcloud projects add-iam-policy-binding concrete-detection-2 \
    --member "serviceAccount:helm-sa@concrete-detection-2-iam.gserviceaccount.com" \
    --role "roles/compute.serviceAgent"

gcloud projects add-iam-policy-binding concrete-detection-2 \
    --member "serviceAccount:helm-sa@concrete-detection-2-iam.gserviceaccount.com" \
    --role "roles/container.serviceAgent"
```


```
gcloud iam service-accounts keys create ./terraform/helm-key.json \
  --iam-account helm-sa@concrete-detection-2.iam.gserviceaccount.com
``` -->



that's it you are good to go with service account.

11. Let us follow the [README.md](README.md#project-overview).

**!Note - Whenever new projects chnage in gcloud then please change DNS nameservers as well in hostinger host.**


## Thank you... :)
