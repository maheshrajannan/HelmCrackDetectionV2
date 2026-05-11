
### GKE cluster and Persistent Disk Creation


1. Ensure variables are set in `environment variables`.

![Set Environment](/docScreenshots/setEnvironment.png)

2. After that we can create `gcloud project`.

![Create GCloud Project](/docScreenshots/createGCloudProject.png)

Let us run shell script to create gCloud Project.

> **NOTE**
> : On completion the name of the project that is created is printed on top of the console.


![Created Gcloud Project](/docScreenshots/createdUIGcloudProject.png)

3. Let us create cluster in the kubernetes engine and persistent disk in the compute engine by running the below shell script.

```
cd clusterPersistetDisk
```

```
sh createClusterPersistentDisk.sh
```

So far we have created a cluster and a persistent disk.

4. Let's refer diagram of persistent disk and how it is referred by persistent volumes and volume claims.

![clusterPD](/docScreenshots/clusterPD.png)

5. The entire project will essentially run inside the cluster.

6. Your cluster and PD are currently prepared for operation. Ensure cluster is created by looking in UI.

![gCloud Version](/docScreenshots/gCloudVersion.png)

Now you can follow the [README.md](README.md#nfs-server-and-volume-creation).


## Thank you... :)