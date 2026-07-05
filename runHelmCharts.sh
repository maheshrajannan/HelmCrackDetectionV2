set -e

cd buildConcreteDetection

# Build all apps
cd imageUpload
sh buildImageUploadImage.sh

cd ../crackDetection
sh buildCrackDetectionImage.sh

cd ../concreteImageGallery

echo "Push the concreteGallery docker image"
sh buildConcreteGalleryImage.sh

echo "Coming to root dir"
cd ../..
echo "Create nfs-server helm chart"
helm upgrade --install nfs-server ./nfsServerChart

sleep 3
NFS_CIP=$(kubectl get svc nfs-server-svc-cip -o jsonpath='{.spec.clusterIP}')
if [[ -z "$NFS_CIP" ]]; then
  echo "ERROR: could not discover nfs-server-svc-cip ClusterIP" >&2
  exit 1
fi
echo "NFS ClusterIP: $NFS_CIP"
sleep 3

echo "Running the 4 child charts in master-chart"
helm upgrade --install master-chart ./masterChart --set pv-chart.nfsCIP="$NFS_CIP" --set global.registry="${DOCKER_USER_ID:-maheshrajannan}"


echo "ImageUpload service."
ImageUploadIp=""
ImageUploadPort=""
while [ -z $ImageUploadIp ]; do
    sleep 5
    ImageUploadIp=`kubectl get service image-upload-svc-lb --output=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    ImageUploadPort=`kubectl get service image-upload-svc-lb --output=jsonpath='{.spec.ports[0].port}'`
done

# Now we will get our image upload IP & PORT.
echo "launch "$ImageUploadIp":"$ImageUploadPort

echo "*"
echo "*"

echo "concreteImageGallery service."
concreteImageGalleryIp=""
concreteImageGalleryPort=""
while [ -z $concreteImageGalleryIp ]; do
    sleep 3
    concreteImageGalleryIp=`kubectl get service concrete-image-gallery-svc-lb --output=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    concreteImageGalleryPort=`kubectl get service concrete-image-gallery-svc-lb --output=jsonpath='{.spec.ports[0].port}'`
done

# Now we will get our image upload IP & PORT.
echo "launch "$concreteImageGalleryIp":"$concreteImageGalleryPort