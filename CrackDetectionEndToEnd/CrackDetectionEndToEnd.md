# Crack Detection — End-to-End Deployment Walkthrough

A step-by-step guide to provisioning a Kubernetes cluster and deploying the concrete
crack-detection app on **both GCP (GKE)** and **DigitalOcean (DOKS)**, driven entirely
from GitHub Actions workflows in this repo.

These steps and screenshots were reconstructed from the `CrackDetectionsEndToEnd.mov`
recording. The order below is the clean, logical flow — in the recording a few steps
were retried (e.g. the macOS `base64` flag), and those gotchas are called out inline.

> Cross-references: `platform-architecture.md` is the authoritative architecture doc.
> The `Mahesh-*` workflows are the canonical/active ones; non-prefixed variants are older.

---

## Prerequisites

Before running any workflow, have these ready:

- Access to the GCP project `concrete-detection-1-491711` and its **Crack Detection Service Account**.
- A **DigitalOcean** account (used for the DOKS path and the Terraform state backend).
- The `doctl` and `gcloud` CLIs installed locally (for connecting to the clusters afterward).
- Push access to the `maheshrajannan/HelmCrackDetectionV2` GitHub repo and its Actions.

---

## Part 1 — Gather credentials

### Step 1. Get the GCP service-account key

In the Google Cloud Console, open **IAM & Admin → Service Accounts → Crack Detection
Service Account → Keys**. This is the key the deploy workflows use to authenticate to
GCP. Existing keys are listed here, and you can **Add Key → Create new key (JSON)** if you
need a fresh one.

![GCP service account keys page](images/01-gcp-service-account-keys.png)

> Google warns against downloading SA keys where avoidable. Keep the downloaded JSON in
> the gitignored `keys/` folder — never commit it.

### Step 2. Encode the SA key as single-line base64

The "Create Kubernetes Cluster" and GKE deploy workflows take the service-account key as a
**single-line base64 string**, not a file. From the `keys/` directory, encode the JSON:

```bash
cd /Users/maheshrajannan/git/HelmCrackDetectionV2/keys

# macOS:
base64 -i concrete-detection-1-491711-4503fa0359cc.json | tr -d '\n' > key2.txt

# Linux:
base64 -w 0 concrete-detection-1-491711-4503fa0359cc.json | tr -d '\n' > key2.txt

cat key2.txt   # copy this value into the workflow input
```

![Encoding the service account key in the terminal](images/02-encode-sa-key-terminal.png)

> **Gotcha (seen in the recording):** macOS `base64` does **not** accept the Linux
> `-w 0` flag — it errors with `invalid argument`. On macOS use `-i <file>` (or just
> pipe and strip newlines with `tr -d '\n'`). Don't paste the literal word "Mac:" into
> the shell.

### Step 3. Log in to DigitalOcean

For the DOKS path, sign in to DigitalOcean (Google or GitHub SSO both work). You'll land
on the dashboard, from which you'll create the Spaces access key and, later, view the
provisioned cluster.

![DigitalOcean login](images/03-digitalocean-login.png)

### Step 4. Create a DigitalOcean Spaces access key (Terraform backend)

Terraform stores its state in a DigitalOcean Spaces (S3-compatible) bucket. Go to
**Spaces Object Storage → Access Keys → Create Access Key**, grant access to the
`terraform-crack-detection` bucket (Full Access is simplest), and give the key a name.

![Create a DigitalOcean Spaces access key](images/04-do-create-spaces-access-key.png)

When the key is created, **copy the secret key immediately** — DigitalOcean shows it only
once. You'll paste both the access key ID and the secret into the workflow inputs.

![DigitalOcean shows the Spaces secret key once](images/05-do-spaces-secret-key.png)

---

## Part 2 — Provision the cluster

### Step 5. Run "Any User – Create Kubernetes Cluster" (GCP inputs)

In GitHub → **Actions → Any User Create Kubernetes Cluster → Run workflow**. Pick the
cloud provider (`GKE` or `DOKS`) and fill the GCP inputs: **GCP project ID**
(`concrete-detection-1-491711`), the **single-line base64 SA key** from Step 2, the
**cluster name**, and the **GKE zone** (`us-central1-a`).

![Create Kubernetes Cluster workflow — GCP inputs](images/06-create-cluster-workflow-gcp-inputs.png)

### Step 6. Fill the DigitalOcean / Terraform inputs

Scrolling the same workflow form, supply the DOKS-side inputs: the **Terraform directory**
to use (e.g. `./terraform/gcp-mahesh` or the DO variant), the **DigitalOcean API token**,
and the **Spaces access key + secret key** from Step 4 (these wire up the Terraform state
backend). Run the workflow to provision the cluster.

![Create Kubernetes Cluster workflow — DigitalOcean / Terraform inputs](images/07-create-cluster-workflow-do-inputs.png)

---

## Part 3 — Deploy the app

### Step 7. GKE path — "Mahesh-GKE-SSL-deploy crack detection"

Run the **Mahesh-GKE-SSL-deploy crack detection** workflow. Provide the base64 GCP SA key,
the **GKE cluster name** (`crack-detection-cluster`), the **zone** (`us-central1-a`), and
the **GCP project ID**. This installs the NFS chart, discovers its ClusterIP, installs the
master Helm chart, and creates the ManagedCertificate + GCE Ingress.

![GKE SSL deploy workflow](images/08-gke-ssl-deploy-workflow.png)

### Step 8. DOKS path — "Mahesh DOK-deploy crack detection"

> **Select the `DO-SSL` branch first.** Before running this workflow, switch to the
> **`DO-SSL`** branch (DigitalOcean SSL path). In the GitHub Actions **Run workflow**
> dropdown, set **"Use workflow from → Branch: `DO-SSL`"** (not `master`).
>
> Note: the recording does not show this branch being selected — the captured GitHub
> Desktop branch switcher (~11:04 AM) still has `githubActionClusterNameFix` checked out,
> with `origin/DO-SSL` only listed, and the DOK-deploy run dropdown defaults to `master`.
> The switch to `DO-SSL` was most likely done in a separate, unrecorded window. Confirm
> the branch in the Run-workflow dropdown before triggering the run.

For DigitalOcean, run the **Mahesh DOK-deploy crack detection** workflow **from the
`DO-SSL` branch**, providing the DigitalOcean API token, the **DOKS cluster name**, and
the ingress name.

![DOKS deploy workflow](images/09-doks-deploy-workflow.png)

### Step 9. Watch the provision/deploy run

Open the run to follow the **Provision Kubernetes Cluster** job. You'll see the Terraform
lifecycle execute in order — `init` → `validate` → `plan` → `apply` — followed by the
DigitalOcean pre-destroy cleanup steps (install `doctl`, delete DO LoadBalancers and Block
Storage Volumes via the API), `Terraform Destroy`, and finally the steps that **output the
cluster connect command** and clean up SSL certificates and the global static IP.

![DOKS provision run — Terraform steps and connect command](images/10-doks-provision-run.png)

> The **Output DOKS cluster connect command** step prints the exact `doctl` commands to
> run locally (see next step).

---

## Part 4 — Connect and verify

### Step 10. Save the kubeconfig with `doctl` (DOKS)

Use the connect command from the workflow output to point `kubectl` at the new DOKS
cluster:

```bash
doctl auth init -t <YOUR_DO_TOKEN>
doctl kubernetes cluster kubeconfig save crack-detection-dok-1
```

![Saving the DOKS kubeconfig with doctl](images/11-doctl-kubeconfig-save.png)

> **Gotcha (seen in the recording):** `kubeconfig save` needs the **exact** cluster name
> or ID. `Error: no cluster goes by the name "..."` means the name is wrong — list
> clusters with `doctl kubernetes cluster list` (or copy the ID from the DO console) and
> retry.

### Step 11. Verify the DOKS cluster in the console

In DigitalOcean → **Kubernetes**, confirm `crack-detection-cluster` is up (region NYC3,
Kubernetes 1.36.x). The Overview tab walks through authenticating, verifying connectivity,
and deploying a workload.

![DigitalOcean cluster overview](images/12-do-cluster-overview.png)

### Step 12. Verify the GKE cluster in the console

For the GCP path, open **Kubernetes Engine → Clusters → crack-detection-cluster**. Confirm
status **Running**, control-plane zone `us-central1-a`, the node count, and the endpoint.
From here the GCE Ingress provisions the L7 load balancer and the Managed Certificate
completes HTTP-01 validation for `maheshconcretegallery.online`.

![GKE cluster details](images/13-gke-cluster-details.png)

---

## What you end up with

- A running GKE **and/or** DOKS cluster named `crack-detection-cluster`.
- The three app components deployed via the master Helm chart (upload :8080,
  crack-detection :8081 internal, gallery :8082), sharing the NFS-backed PVC.
- On GKE: a GCE Ingress + Managed Certificate serving the gallery over HTTPS.

Flow at runtime: the upload pod writes images → the crack-detection pod processes them
(`x.png` → `x-processed.png`) → the gallery pod serves original vs processed images.

---

*Screenshots auto-extracted from `CrackDetectionsEndToEnd.mov` via scene detection, then
curated. Captions are reconstructed from on-screen content and the repo's
`platform-architecture.md`; verify exact input values against the live workflow forms
before running.*
