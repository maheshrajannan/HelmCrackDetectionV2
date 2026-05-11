## 1. If you running entire application and it's not properly detecting cracks and showing blank instead of processing,

![Not Detecting](/docScreenshots/noDetection.jpeg)

### Solution

- *You just have to change the tag of `docker image` everywhere.*

## 2. If you get error like `CrashLoopBack off`

ERROR : CrashLoopBack off

container pod is giving the error like this then see the logs of container

```
kubectl logs -f << pod name >>
```

Otherwise you can describe the pod also

```
kubectl describe po << pod name >>
```
![Describe Pod](/docScreenshots/describePod.png)

So you will get the location of problem.

## 3. If you get error related port like this

ERROR : Building ImageUpload-logic component in no hup mode
docker: Error response from daemon: driver failed programming external connectivity on endpoint relaxed_swanson (48bcaf8c4123d12a10801848759808da8e445169a0a3da4489ac9a5bbca34008): Bind for 0.0.0.0:3000 failed: port is already allocated.

**Then you can use this command**

```
sudo kill -9 $(sudo lsof -t -i:<< port >>)
```

## 4. If docker login give error then also try to re-run shell script OR do docker login once.

### Whenever you see log of [buildCrackDetectionImage.sh](crackDetection/app/buildCrackDetectionImage.sh) and it's stuck pushing to dockerhub

### Solution

Just run again the crack detection app and you will solved your problem.

- Sometimes you got error message when you build docker image you OR push the docker image to dockerHub.

- So you need to just Re-run that shell script OR command.

```
gcloud container clusters get-credentials node-python-cluster
```

![Cluster Credentials](/docScreenshots/clusterCredentials.png)

## 5. If you want to check inside the pod for any operation

To login the pod use the command

```
kubectl exec -it << pod-name >> -- /bin/bash
```
![Pod Structure](/docScreenshots/podStructure.png)

- You can check the crackDetection pod and you will get detected image on particular path.
In our case the path is /app/uploads/images/completed.


## Thank you... :)