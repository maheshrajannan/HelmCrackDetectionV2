#!/bin/sh
abort()
{
    echo >&2 '
***************
*** ABORTED buildConcreteGalleryLogicDocker ***
***************
'
    echo "An error occurred buildConcreteGalleryLogicDocker . Exiting..." >&2
    exit 1
}

trap 'abort' 0

set -e
#TODO: add check to ensure the user is logged in.

echo "Please ensure you are logged in to docker / docker desktop"
# source ~/.bash_profile

export set LEVEL=DEBUG

# LEVEL=NONDEBUG
if [ "$LEVEL" = "DEBUG" ]; then
	echo "Level is DEBUG.Press Enter to continue."
	read levelIsDebug	
else
	echo "Level is NOT DEBUG. There will be no wait."	
fi

#Kill the process
unset DOCKER_HOST
unset DOCKER_TLS_VERIFY
unset DOCKER_TLS_PATH
echo "Trying to login. If you are NOT logged in, there will be a prompt"
docker login
docker ps

CURRENT_DATE=`date +%b-%d-%y_%I_%M_%p`
echo "CURRENT_DATE:"+$CURRENT_DATE

# It will print the log folder wise
echo "Building concrete-gallery-logic"
docker build -f dockerfile -t $DOCKER_USER_ID/concrete-image-gallery-logic:latest .

# Now image building is done 
# So now we will push that image to dockerhub
echo "Pushing concrete-image-gallery-logic"
docker push $DOCKER_USER_ID/concrete-image-gallery-logic:latest

# docker pull $DOCKER_USER_ID/concrete-image-gallery-logic:latest

trap : 0

echo >&2 '
************
*** DONE buildConcreteGalleryLogicDocker ***
************'