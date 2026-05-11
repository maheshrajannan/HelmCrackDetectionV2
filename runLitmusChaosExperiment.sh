set -e

echo "======================================================"
echo "          LitmusChaos Test Automation Script          "
echo "======================================================"

read -p "Do you want to run the LitmusChaos test? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborting LitmusChaos automation."
    exit 0
fi

echo "Applying Chaos Test YAML..."

# 🔥 Pick latest downloaded YAML automatically
LATEST_FILE=$(ls -t ~/Downloads/crack-detection-litmus-chaos-enable*.yml 2>/dev/null | head -n 1)

if [ -n "$LATEST_FILE" ]; then
    echo "Using latest file: $LATEST_FILE"
    kubectl apply -f "$LATEST_FILE"
    echo "Successfully applied latest Chaos Test YAML."
elif [ -f "./crack-detection-litmus-chaos-enable.yml" ]; then
    echo "Using file from current directory"
    kubectl apply -f ./crack-detection-litmus-chaos-enable.yml
    echo "Successfully applied Chaos Test YAML from current directory."
else
    echo "Error: No chaos YAML file found."
    echo "Please ensure the file exists in ~/Downloads or current directory."
fi

echo "======================================================"
echo "          LitmusChaos Setup Complete!                 "
echo "======================================================"