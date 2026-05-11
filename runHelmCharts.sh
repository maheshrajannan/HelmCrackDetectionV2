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
helm install nfs-server ./nfsServerChart

sleep 3
echo "Run python file to populate Cluster-IP"
python3 populateCIP.py
sleep 3

echo "Running the 4 child charts in master-chart"
helm install master-chart ./masterChart


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