#!/bin/sh
# INFO: if it fails reinitialize gcloud init.
# INFO: change the name of project in environment variables.sh and source it again. 
# Then run this.
abort()
{
    echo >&2 '
***************
*** ABORTED gCloudProjectCreate.sh ***
***************
'
    echo "An error occurred in gCloudProjectCreate.sh . Exiting..." >&2
    exit 1
}

trap 'abort' 0

set -ex

# Check if the project exists
if gcloud projects describe $PROJECT_ID; then
    # If the project exists, print a message
    echo "Project $PROJECT_ID already exists"
else
    # If the project does not exist, create it
    echo "Creating project $PROJECT_ID"
    gcloud projects create $PROJECT_ID
fi



# gcloud auth login
# gcloud config set project [PROJECT_ID]

# Now enable APIs using this command after that command it will take few minutes longer
# Let's enable compute engine api

# gcloud services enable compute.googleapis.com

# Now enable kubernetes Engine api

# gcloud services enable container.googleapis.com

trap : 0

echo >&2 '
************
*** DONE gCloudProjectCreate.sh ***
************'