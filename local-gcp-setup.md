# Connecting to Google Cloud from your local machine

How to go from a clean laptop to a working `kubectl` / `helm` session against the
GKE cluster for this project. This is the missing "day‑0" guide: install the tools,
authenticate, point at the right project, and pull cluster credentials.

> Reference values for the **current active stack** (see `CLAUDE.md`):
>
> | Thing | Value |
> |---|---|
> | GCP project ID | `concrete-detection-1-491711` |
> | GKE cluster name | `crack-detection-cluster` |
> | Zone | `us-central1-a` |
> | Region | `us-central1` |
> | TF state bucket | `crack-detection-terraform` |
> | Service-account key (local) | `keys/concrete-detection-1-491711-4503fa0359cc.json` |
>
> If you are standing up a **new** project, change the project ID here and follow
> [runbooks.md → Change the GCP project ID](runbooks.md#change-the-gcp-project-id).

---

## 1. Install the tools

You need four CLIs: `gcloud`, the GKE auth plugin, `kubectl`, and `helm`.

**macOS (Homebrew)**

```bash
# Google Cloud SDK
brew install --cask google-cloud-sdk

# kubectl + the GKE auth plugin (REQUIRED for get-credentials on recent gcloud)
gcloud components install kubectl gke-gcloud-auth-plugin
# or, via brew:
brew install kubectl
gcloud components install gke-gcloud-auth-plugin

# Helm
brew install helm
```

**Linux**

```bash
# gcloud SDK – follow https://cloud.google.com/sdk/docs/install, then:
gcloud components install kubectl gke-gcloud-auth-plugin

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
gcloud version
kubectl version --client
helm version
gke-gcloud-auth-plugin --version
```

> **Why the auth plugin matters:** recent `gcloud` no longer ships the in‑tree GKE
> auth provider. Without `gke-gcloud-auth-plugin`, `kubectl` commands fail with
> `getting credentials: exec: executable gke-gcloud-auth-plugin not found`.
> Set `USE_GKE_GCLOUD_AUTH_PLUGIN=True` in your shell profile if you run an older gcloud.

---

## 2. Authenticate

There are two ways. Pick **one**.

### Option A — Interactive login (recommended for humans)

Use this on your own workstation. It opens a browser and links your Google
identity to the local CLI.

```bash
gcloud auth login            # browser-based user login
gcloud auth application-default login   # also set up ADC, used by Terraform/SDKs
```

### Option B — Service-account key (used by CI; works locally too)

The repo's GitHub Actions authenticate with a service-account JSON key stored as
the secret `MAHESH_GCP_CD_2_SA_KEY`. The same key file lives locally (gitignored)
at `keys/concrete-detection-1-491711-4503fa0359cc.json`.

```bash
gcloud auth activate-service-account \
  --key-file="keys/concrete-detection-1-491711-4503fa0359cc.json"

# Make SDK/Terraform use the same key (Application Default Credentials)
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/keys/concrete-detection-1-491711-4503fa0359cc.json"
```

> ⚠️ **Never commit keys.** `keys/` is gitignored. If a key is ever committed or
> shared, treat it as compromised and rotate it — see
> [runbooks.md → Rotate the GCP service-account key](runbooks.md#rotate-the-gcp-service-account-key).

---

## 3. Point at the project

```bash
gcloud config set project concrete-detection-1-491711
gcloud config set compute/zone us-central1-a
gcloud config set compute/region us-central1

# Sanity check
gcloud config list
gcloud projects describe concrete-detection-1-491711
```

If this is a brand-new project, enable the APIs the stack needs:

```bash
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  dns.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com
```

---

## 4. Get cluster credentials

This writes a context into your `~/.kube/config`:

```bash
gcloud container clusters get-credentials crack-detection-cluster \
  --zone us-central1-a \
  --project concrete-detection-1-491711
```

Verify you're connected:

```bash
kubectl config current-context
kubectl get nodes
kubectl get pods -A
```

You should see the four app pods once deployed:

```
NAME                                           READY   STATUS    RESTARTS   AGE
concrete-image-gallery-depl-...                1/1     Running   0          ...
crack-detection-depl-...                       1/1     Running   0          ...
image-upload-depl-...                          1/1     Running   0          ...
nfs-server-depl-...                            1/1     Running   0          ...
```

---

## 5. (Optional) Docker / DockerHub for building images

The three app images are pushed to DockerHub under `maheshrajannan/`. To build and
push your own:

```bash
docker login                       # DockerHub creds (CI uses MAHESH_DOCKER_USERNAME/PASSWORD)
cd buildConcreteDetection
# build scripts read $DOCKER_USER_ID — set it to YOUR DockerHub org if not maheshrajannan (defaults to maheshrajannan)
export DOCKER_USER_ID=<your-dockerhub-user>
```

If you change the DockerHub org, override the `global.registry` key in `masterChart/values.yaml` or use Helm's `--set global.registry=<your-dockerhub-user>` flag at deploy time.

---

## 6. Common pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `gke-gcloud-auth-plugin not found` | Auth plugin not installed | `gcloud components install gke-gcloud-auth-plugin` |
| `get-credentials` succeeds but `kubectl` is 403 | SA lacks `roles/container.developer` | Grant the role (see runbooks → project setup) |
| `mkcert <domain>` aborts on `keytool` | Broken `JAVA_HOME` / `keytool` on PATH | Prefix with `JAVA_HOME=` or `unset JAVA_HOME` |
| Pods stuck `ContainerCreating`, NFS mount fails | PV points at a stale NFS ClusterIP | Re-inject `pv-chart.nfsCIP` at deploy time (don't use the committed value) |
| Wrong project after `gcloud init` | `init` reset the active config | Re-run `gcloud config set project ...` |

---

## 7. Tear down when done

To avoid charges, destroy the cluster and verify nothing is left behind. See
[runbooks.md → Teardown and verification](runbooks.md#teardown-and-verification).
