#!/bin/sh
abort()
{
    echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred in RunImageUploadLocally.sh . Exiting..." >&2
    exit 1
}

trap 'abort' 0

set -e
#RunSentimentAnalyzer.sh
# if you get xcode error. xcode-select --install
# https://ma.ttias.be/mac-os-xcrun-error-invalid-active-developer-path-missing-xcrun/
CURRENT_DIR=`pwd`
CURRENT_DATE=`date +%b-%d-%y_%I_%M_%S_%p`
# Switch to root folder and run.
cd ../
echo "`pwd`"
mkdir logs/$CURRENT_DATE
cd app
echo "Started imageUploadApp. Do tail -f logs/imageUploadImage.log from "+$CURRENT_DIR
#open -a Terminal $CURRENT_DIR/logs
# You need to enter into node file directory
# You have to install first node modules 
npm install

# Now you can start the npm 
npm start

trap : 0

echo >&2 '
************
*** DONE RunImageUploadLocally ***
************'