# Local Google Cloud Setup and Cluster Connection Guide

This guide explains how to set up your local environment to connect to and manage your Google Kubernetes Engine (GKE) cluster.

## 1. Install Google Cloud CLI

If you haven't already, install the `gcloud` CLI:
- **Linux/Mac/Windows**: Follow the [official installation instructions](https://cloud.google.com/sdk/docs/install).

## 2. Authenticate with Google Cloud

Authenticate your CLI with your Google account:

```bash
gcloud auth login
```

### Option: Interactive Setup (Recommended for first-time use)

Alternatively, you can run `gcloud init` to perform authentication, project selection, and default zone configuration in one interactive process:

```bash
gcloud init
```

If you are using a Service Account (common in automated environments):

```bash
gcloud auth activate-service-account --key-file=path/to/your-key.json
```

## 3. Set Your Project ID

Set the default project for your CLI session:

```bash
# Replace <YOUR_PROJECT_ID> with your actual GCP project ID
gcloud config set project <YOUR_PROJECT_ID>
```

To find your project ID, run: `gcloud projects list`

## 4. Install GKE Auth Plugin

Google Cloud now requires a separate authentication plugin for `kubectl` to interact with GKE.

### Linux (Debian/Ubuntu)
```bash
sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin
```

### macOS
```bash
brew install google-cloud-sdk
gcloud components install gke-gcloud-auth-plugin
```

### verification
Verify installation:
```bash
gke-gcloud-auth-plugin --version
```

## 5. Connect to Your GKE Cluster

Run the following command to retrieve the cluster credentials and update your `kubeconfig` file.

```bash
# Replace placeholders with your cluster details
gcloud container clusters get-credentials <CLUSTER_NAME> \
    --zone <CLUSTER_ZONE> \
    --project <PROJECT_ID>
```

> [!TIP]
> You can find these values in the GitHub Actions workflow logs after a successful cluster deployment.

## 6. Verify Connection

Once connected, verify that you can reach the cluster:

```bash
kubectl get nodes
kubectl cluster-info
```

You should see a list of your GKE nodes and cluster endpoint information.
