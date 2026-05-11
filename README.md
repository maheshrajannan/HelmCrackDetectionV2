<img src="https://avatars2.githubusercontent.com/u/2810941?v=3&s=10000" alt="Google Cloud Platform logo" title="Google Cloud Platform" align="right" height="150" width="150"/>

# Concrete Crack Detection Through a 3 Part Application

   *This application has 3 components. It analyses uploaded concrete photos to find cracks. This is implemented and deployed locally first, then to GCLoud. We will do all of this in a hands on manner.*

## Audience

   1. Students

   2. Cloud and CI/CD newbies

## At a Glance

In this repository we will use an application that has 3 components to demonstrate `detecting cracks in concrete`.

   1. The first component is a web application that does `image upload`. It is written in react js.

   2. A Python application component that finds the crack in the uploaded image.

   3. The third application component is a node Js web app. It displays raw concrete images and their corresponding analyzed images with cracks in gallery format.

   4. There isn't a lot of technical jargon.

   5. The main focus is to quick start with a running app.

## Objective

The objective is,

   1. Ensure that app is running locally.

   2. Deploy the app locally.

   3. Containerize it.

   4. Then move to GCP on the cloud.

The purpose is NOT,

   1. Learning Kubernetes or Docker in depth.

   2. Learning a specific method or concept.

   3. Advanced Learning.


## Pre-requisite

**Setup & configuration of gCloud and Docker**

   Let us follow this for setup and documentation, see [here](gCloudDockerSetup.md).

   Follow [these](runningLocally.md) 3 steps for installing the app locally.

   Before starting a running app, let's first make sure we understand the background.

## Project Overview

   Let's see the entire infrastructure(gcloud components) in a single diagram.

   ![Crack Detection Diagram](/docScreenshots/concreteCrackDetectionDiagram.png)

> **Note**
> : Some information ommited for simplicity.

## Running the application

   Let's run each application component one at a time.

### GKE cluster and Persistent Disk creation

   **Step-1** Let us install GKE Cluster and Persistent Disk, by following [this](clusterPd.md) page.

### NFS server and volume creation

   **Step-1** Let us follow this [guide](nfsServer.md) to create an NFS server.


### Let us run the following 3 shell scripts to launch 3 components of application

   **Step-1** As a result, we have also created a `clusterPd`, `NFS server`, and `pvPvc`.

   **Step-2** Let us run `3 components of application` that are ready to launch.

   Let see 3 components of application in below diagram.

   ![3 components of web application](/docScreenshots/3components.png)

   **Step-3** There are 3 components that are all connected to the same `PVC`.

   **Step-4** Let see folder structure.

   ![Folder Structure of components](/docScreenshots/folderStructure.png)


   **Step-5** Three components have the following 5 folders. Let see below picture.

   ![Inside Component](/docScreenshots/insideComponent.png)

   1) **app** :- Inside this folder we will get the set of instructions for building a specific component, along with a `dockerfile`.

   2) **gKE** :- Inside this folder we will get `shell script` to run specific components.

   3) **local** :- Inside this folder we will get `shell script` and `local.md` files to understand and run components `locally`.

   4) **logs** :- Inside this folder we will get `logs` of the app when it creates a `docker image` and pushing it on dockerhub.

   5) **resourceManifests** :- Inside this folder we will get `YAML` files for deployment and services of gcloud.

### Image Upload Component

   **Step-1** Let us use this command to navigate to the `imageUpload/gKE` folder.,

   ```
   cd /imageUpload/gKE
   ```

   **Step-2** Let us execute the imageUpload shell script,


   ![Run Image Upload](/docScreenshots/runImageUpload.png)


   ```
   sh gCloudDepImageUpload.sh
   ```

   **Step-3** After getting `port`(Without getting error) let us copy and paste the port in browser.

   ![Created Image Upload](/docScreenshots/createdImageUpload.png)


   **Step-4** Let us click the `upload image` button when it appears and then choose a `cracked` image from local device.


   ![Dashboard of Image Upload](/docScreenshots/imageUpload.png)


   **Step-5** The images are stored in the `/app/uploads/images` folder after being uploaded to the PVC's mountpath.

   ![PVC Mountpath](/docScreenshots/pvcMountpath.png)

   **Step-6** This component allows us to upload pictures from local device.

### Crack Detection App

   **Step-1** Let us return to the app's `root location` first.

   **Step-2** Let us run this command to navigate to the `cracDetection/gKE` folder.

   ```
   cd /crackDetection/gKE
   ```

   **Step-3** Let us run the crackDetection shell script.


   ![Run Crack Detactiion](/docScreenshots/runCrackDetection.png)


   ```
   sh gCloudDepCrackDetection.sh
   ```

   **Step-4** To use this component, just run it with a upper command and the port will show up in terminal(NO need to run in browser), that's it. 

   **Step-5** This component will identify the image's crack and change the filename. eg. changing `xyz.png` to `xyz-proccessed.png`.

   **Step-6** Therefore, this component will process the images found in `app/uploads/images` and send the processed and original images to the `app/uploads/images/completed` folder. To see these images, we need to run the component shown below👇.

### Concrete Image Gallery component

   **Step-1** Let us return to the application's `root location`.

   **Step-2** Let us run this command to navigate to the `concreteImageGallery/gKE` folder.

   ```
   cd /concreteImageGallery/gKE
   ```

   **Step-3** Let us run the concreteImageGallery shell script,

   ```
   sh gCloudDepConcreteImageGallery.sh
   ```


   ![Run Concrete Image Gallery](/docScreenshots/runConcreteImageGallery.png)


   **Step-4** After run the component, a port will appear.


   ![Created Concrete Image Gallery](/docScreenshots/createdConcreteGallery.png)


   **Step-5** Let us run that port on browser, then we will be able to see both the original and processed images on the webpage that opens up.

   ![Concrete Image Gallery](/docScreenshots/concreteImageGallery.png)

   * Refer to [this](troubleShootingCommands.md) if you encounter any errors or problems.

### Delete the Cluster and Project in gCloud

   **Step-1** Let us go to the `root folder` to delete the cluster first.

   ```
   cd /clusterPersistetDisk
   ```

   **Step-2** Let us run the delete cluster shell script by using below command,

   ```
   sh deleteClusterPersistentDisk.sh
   ```

   ![Delete Cluster](/docScreenshots/deleteCluster.png)

   > **Note**
   > : Kindly delete `gcloud project` after running your application successfully, otherwise it will cost you hundreds of dollars and we are not reponsible for that.

   **Step-3** If we run the below shell script, we can even delete the `gCloud project` (change the project name as per requirement).

   ```
   sh gCloudProjectDelete.sh
   ```
   ![Delete Gcloud Project](/docScreenshots/deleteGcloudProject.png)

   * This will take some time to completely shutdown.
   * After deleting project all of the resources have been completely deleted, Excellent work😊.

## Thank you... :)
