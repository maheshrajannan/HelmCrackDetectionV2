#!/bin/sh
abort()
{
    echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred in runCrackDetectionLocally.sh . Exiting..." >&2
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
echo "Started CrackDetection. Do tail -f logs/crackDetectionImage.log from "+$CURRENT_DIR
#open -a Terminal $CURRENT_DIR/logs
# You need to enter into python file directory

pip3 install opencv-python

pip3 install opencv-contrib-python

pip install -r requirements.txt

python crackDetection.py



trap : 0

echo >&2 '
************
*** DONE runCrackDetectionLocally ***
************'