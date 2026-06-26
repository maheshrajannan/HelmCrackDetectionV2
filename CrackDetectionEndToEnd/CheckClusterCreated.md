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

---

# Local DigitalOcean Setup and Cluster Connection Guide

This guide explains how to set up your local environment to connect to and manage your DigitalOcean Kubernetes (DOKS) cluster.

## 1. Install doctl (DigitalOcean CLI)

### Linux
```bash
curl -sL https://github.com/digitalocean/doctl/releases/download/v1.97.0/doctl-1.97.0-linux-amd64.tar.gz | tar -xz
sudo mv doctl /usr/local/bin/
```

### macOS
```bash
brew install doctl
```

### Windows
Download the latest release from the [doctl releases page](https://github.com/digitalocean/doctl/releases) and add it to your PATH.

Verify installation:
```bash
doctl version
```

## 2. Authenticate with DigitalOcean

Generate a Personal Access Token from [https://cloud.digitalocean.com/account/api/tokens](https://cloud.digitalocean.com/account/api/tokens) with **Read** and **Write** scopes, then authenticate:

```bash
doctl auth init -t <YOUR_DO_API_TOKEN>
```

Verify authentication:
```bash
doctl account get
```

## 3. List Your DOKS Clusters

Check available clusters in your account:

```bash
doctl kubernetes cluster list
```

## 4. Connect to Your DOKS Cluster

Run the following command to fetch credentials and update your local `kubeconfig`:

```bash
# Replace <CLUSTER_NAME> with your actual DOKS cluster name
doctl kubernetes cluster kubeconfig save <CLUSTER_NAME>
```

> [!TIP]
> The default cluster name used in this project is `crack-detection-cluster`.
> You can find the exact name in the GitHub Actions workflow logs after a successful cluster deployment.

## 5. Verify Connection

Once connected, verify that you can reach the cluster:

```bash
kubectl get nodes
kubectl cluster-info
```

You should see a list of your DOKS nodes and cluster endpoint information.

## 6. Switch Between Clusters (Optional)

If you manage multiple clusters (e.g. GKE and DOKS), you can switch between contexts:

```bash
# List all available contexts
kubectl config get-contexts

# Switch to your DOKS cluster context
kubectl config use-context do-<REGION>-<CLUSTER_NAME>
```
