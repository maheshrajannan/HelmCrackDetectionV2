#!/bin/sh
abort()
{
    echo >&2 '
***************
*** ABORTED gCloudProjectDelete.sh ***
***************
'
    echo "An error occurred in gCloudProjectDelete.sh . Exiting..." >&2
    exit 1
}

trap 'abort' 0

set -ex

unset DOCKER_HOST
unset DOCKER_TLS_VERIFY
unset DOCKER_TLS_PATH
# INFO: https://stackoverflow.com/questions/30604846/docker-error-no-space-left-on-device
echo "INFO: Docker system pruning to save space:"
docker system prune -f

# Check if the project exists
if gcloud projects describe $PROJECT_ID &> /dev/null; then
  # Delete the project if it exists
  echo "Deleting GCP project $PROJECT_ID"
  gcloud projects delete $PROJECT_ID #--quiet
else
  # Output a message if the project does not exist
  echo "GCP project $PROJECT_ID does not exist"
fi

# You can undo this operation for a limited period by running the command below.
# $ gcloud projects undelete $PROJECT_ID

trap : 0

echo >&2 '
************
*** DONE gCloudProjectDelete.sh ***
************'