## Gcloud bucket creation

- We've to create bucket for the storing of the terraform tf.state file so that we can delete the same k8s cluster by github action pipeline which k8s cluster created by pipeline.
![bucket](/docScreenshots/gcloudBucket.png)
- The configuration of bucket setup is in main.tf file and github action workflow file.


## Github Action Secrets creation

- Here We've created github action secrets for gcloud service account key json file and gcloud project ID.
- First we need to go below location
![secrets](/docScreenshots/secret-list.png)
- Now we need to click on add secret button and I've laso given example of how can we add that.
![secrets](/docScreenshots/secret-creation.png)
- Now other all the secret I've created using this way.