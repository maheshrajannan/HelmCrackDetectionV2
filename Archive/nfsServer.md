## Create a NFS server and volume

1. Let us now create `NFS server` and `PV-PVC` after creating cluster and persistent disk (PD) .

Let see below diagram.

![NFS Server](/docScreenshots/nfsServer.png)

2. This container, which has a `gcr.io` image and a nfs volume, is visible.

3. Container Image, is an application packaging mechanism, where all the dependencies to run the application are packaged together. For example a Java application to read files  is packaged as a jar along with a basic JRE and it can run on its own. More on this later. This is all we need to know now.

4. Container is created from a (Self-contained) image and it has the application up and runnning.

5. A pod is made up of one or more containers.

6. After the pod has been created, it can be made accessible on a specific port by a nfs-service.

7. Let's see persistent volume(PV) and the persistent volume claim(PVC).

Let's see below diagram.

![PV-PVC](/docScreenshots/pvPvc.png)

8. When creaitng PVC, If there is already a PV, then the PVC will use it. But if there is no PV, then PVC will be created by default.

9. Make sure default is not used when creating PVC. Images will not be save ,and the application will not work, if default PV is used.

10. We will be using the `ReadWriteMany` (RWM) access mode in this case because we will be running 3 components on a single volume.

> **Note**
> : Remember that both PV and PVC storage have a maximum size of 10 Gi. This is because the Compute Engine persistent disk(main storage) we created was 10Gi. we can choose any storage size for PVC as long as it is not bigger than the storage size specified for PV.

The following tasks are automated (by shell script nfs),

11. Create a persistent volume using the `cluster IP`, which was created when creating nfs-service.

12. Include the cluster IP in the PV's yaml file.

> **Note** 
> : We will receive a new cluster IP every time a NFS service is created. So the new cluster ip should must updated in the PV's yaml file.This using the "sed" command.

13. Cluster IP is nothing but an internal ip, through which the pods inside the cluster can communicate.

14. This cluster ip is needed to configure the upload image pod and crack detection pod, so that they store the images in the shared place.

15. In this case, we need to run one shell script to complete this entire operation (NFS server and pvPvc).

Let us navigate to the nfsServerPvPvc folder,

```
cd /nfsServerPvPvc
```

Let us run the shell script,

```
sh nfsServer.sh
```

![Created NFS Server](/docScreenshots/createdNFSServer.png)

16. Now let us follow the [README.md](README.md#let-us-run-the-following-3-shell-scripts-to-launch-3-components-of-application).

## Thank you... :)