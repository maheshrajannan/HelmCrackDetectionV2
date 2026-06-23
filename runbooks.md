# Operations runbooks

Step-by-step procedures for the reproducibility-sensitive operations on this stack:
rotating keys, changing the project, renaming the cluster, knowing which secrets are
required, and tearing everything down cleanly.

These exist because those operations were previously undocumented and several values
are hardcoded in more than one place — so a change in one spot silently leaves stale
copies elsewhere. Each runbook lists **every** location you must touch. See the
companion audit issues (GitHub) for the underlying defects and the
`local-gcp-setup.md` guide for first-time setup.

**Active stack values** — project `concrete-detection-1-491711`, cluster
`crack-detection-cluster`, zone `us-central1-a`, region `us-central1`, TF state
bucket `crack-detection-terraform`.

> Convention: the `Mahesh-*` workflows and `*-mahesh` Terraform dirs are the active
> path. Non-prefixed variants are legacy and carry **different** hardcoded values —
> confirm which one you actually run before editing.

---

## Rotate the GCP service-account key

Do this on a schedule, and immediately if a key is ever committed, logged, or shared.

1. **Find the service account** the current key belongs to:

   ```bash
   gcloud iam service-accounts list --project concrete-detection-1-491711
   # note the SA email, e.g. crack-detection-1@concrete-detection-1-491711.iam.gserviceaccount.com
   ```

2. **Create a new key:**

   ```bash
   SA=<sa-email-from-step-1>
   gcloud iam service-accounts keys create keys/new-sa-key.json \
     --iam-account "$SA" --project concrete-detection-1-491711
   ```

3. **Base64-encode it** for the GitHub secret (CI consumes the raw JSON via
   `google-github-actions/auth`, but keep encoding consistent with how the secret
   was originally stored):

   ```bash
   # raw JSON is what google-github-actions/auth expects:
   cat keys/new-sa-key.json
   ```

4. **Update the GitHub secret** `MAHESH_GCP_CD_2_SA_KEY` (repo → Settings → Secrets
   and variables → Actions). Paste the new key JSON.

5. **Update local ADC** if you authenticate locally with the key:

   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/keys/new-sa-key.json"
   gcloud auth activate-service-account --key-file="$PWD/keys/new-sa-key.json"
   ```

6. **Disable, then delete the old key** once the new one is verified working
   (run a workflow / `kubectl get nodes`):

   ```bash
   gcloud iam service-accounts keys list --iam-account "$SA"
   gcloud iam service-accounts keys delete <OLD_KEY_ID> --iam-account "$SA"
   ```

7. **Rotate sibling secrets** if they were issued from the same compromised source:
   `MAHESH_DIGITALOCEAN_ACCESS_TOKEN`, `MAHESH_DO_ACCESS_KEY_ID`,
   `MAHESH_DO_SECRET_ACCESS_KEY`, and the DOKS TLS PEMs in `keys/DOKKeys/`.

> The local filename `concrete-detection-1-491711-4503fa0359cc.json` encodes the old
> key ID (`4503fa0359cc`). After rotation, update `local-gcp-setup.md` and any local
> `GOOGLE_APPLICATION_CREDENTIALS` export to the new filename.

---

## Change the GCP project ID

The project ID is hardcoded in **multiple** distinct files (and the legacy paths use
*different* IDs). To move the active stack to a new project, update **all** of these:

| File | What to change |
|---|---|
| GitHub repo **variables/secrets** | `MAHESH_GCP_PROJECT_ID` and `MAHESH_GCP_PROJECT` (both are referenced — keep them in sync) |
| `.github/workflows/Mahesh-Cluster.yaml` | line ~61 hardcodes `gcloud config set project concrete-detection-1-491711` — change to `${{ secrets.MAHESH_GCP_PROJECT_ID }}` |
| `terraform/gcp-bootstrap-mahesh/variables.tf` | `project_id` default |
| `terraform/gcp-mahesh/` | confirm provider uses `var.project_id`, not a literal |
| `local-gcp-setup.md`, `platform-architecture.md` | reference values |

After changing the project:

1. Create/choose the new GCS state bucket and update the backend (see next runbook
   note) — backend bucket names can't be variabilized, they're edited in
   `terraform/gcp-mahesh/backend.tf` and `terraform/gcp-bootstrap-mahesh/main.tf`.
2. Enable the required APIs in the new project (see `local-gcp-setup.md` §3).
3. Create the service account + key in the new project and update
   `MAHESH_GCP_CD_2_SA_KEY` (see the rotation runbook above).
4. **Change DNS nameservers in Hostinger** to the new Cloud DNS zone's NS records —
   the SSL/managed-cert path won't validate otherwise.

> Known inconsistency: some steps read `secrets.MAHESH_GCP_PROJECT_ID` while the
> "connect command" echo reads `vars.MAHESH_GCP_PROJECT`. Set **both** to the same
> value until this is consolidated.

---

## Change the cluster name

The cluster `name` is **force-new** in Terraform: changing it against existing state
**destroys and recreates** the cluster — it does not rename. Plan for downtime/data
loss (NFS uses `emptyDir`, so uploaded images are lost regardless).

Update every location:

| File | Line | Note |
|---|---|---|
| GitHub variable/secret | — | `MAHESH_GKE_CLUSTER_NAME` (if wired) |
| `terraform/gcp-mahesh/main.tf` | `name = var.cluster_name` | already variabilized (default `crack-detection-cluster`); pass a new `cluster_name` input |
| `terraform/gcp/main.tf` | `name = "crack-detection-cluster"` | **legacy path still hardcoded** — fix to `var.cluster_name` if you use it |
| `.github/workflows/Mahesh-Cluster.yaml` | ~101, ~221 | connect-command echoes hardcode `crack-detection-cluster` — change to the input |
| DO workflows (`Mahesh-DO-*`, `deploy-DOK.yaml`) | various | `doctl kubernetes cluster kubeconfig save crack-detection-cluster` literals |

Then:

```bash
# apply via the Mahesh-Cluster workflow with the new cluster_name input, OR locally:
cd terraform/gcp-mahesh
terraform plan -var="cluster_name=<new-name>"
terraform apply -var="cluster_name=<new-name>"

# re-pull credentials under the new name
gcloud container clusters get-credentials <new-name> \
  --zone us-central1-a --project concrete-detection-1-491711
```

---

## Change region / zone

`region`/`zone` are partly hardcoded. To move the cluster:

- `terraform/gcp-mahesh/main.tf` — `region` is a literal `us-central1`; the cluster
  uses `var.zone`. Make `region` a variable too.
- `terraform/gcp-mahesh/nodepool-autoscaling.tf` — node-pool `location` is a literal
  `us-central1-a`. **Set it to `var.zone`** or the node pool and cluster can land in
  different zones (broken cluster).
- Update `gcloud config set compute/zone|region` and the `get-credentials --zone`
  flag everywhere (workflows + `local-gcp-setup.md`).

---

## Required GitHub secrets and variables (inventory)

Recreate this exact set when forking or moving the repo. Names are referenced across
the `Mahesh-*` workflows.

**Secrets**

| Secret | Used for |
|---|---|
| `MAHESH_GCP_CD_2_SA_KEY` | GCP service-account JSON key (auth) |
| `MAHESH_GCP_PROJECT_ID` | GCP project ID (most steps) |
| `MAHESH_DOCKER_USERNAME` | DockerHub login |
| `MAHESH_DOCKER_PASSWORD` | DockerHub login |
| `MAHESH_DIGITALOCEAN_ACCESS_TOKEN` | DOKS provisioning |
| `MAHESH_DO_ACCESS_KEY_ID` | DO Spaces (TF state) |
| `MAHESH_DO_SECRET_ACCESS_KEY` | DO Spaces (TF state) |
| `MAHESH_TLS_CERT_BASE64` | DOKS TLS secret cert |
| `MAHESH_TLS_KEY_BASE64` | DOKS TLS secret key |

**Variables**

| Variable | Used for |
|---|---|
| `MAHESH_GCP_PROJECT` | project ID in connect-command echo (keep in sync with the secret) |

> There was previously no single inventory; secrets had to be discovered by reading
> every workflow. Keep this table updated when a workflow adds a new secret.

---

## Teardown and verification

Destroy steps key off **hardcoded resource names** (static IP `concrete-detection-ip`,
cert `concrete-gallery-cert`). If a resource was created under a different name, the
destroy silently skips it and **leaks billable resources**. Always verify after destroy.

1. **Destroy the cluster** (via the workflow's destroy path or locally):

   ```bash
   cd terraform/gcp-mahesh
   terraform destroy
   ```

2. **Verify nothing billable remains:**

   ```bash
   # Global static IP (billable when unattached)
   gcloud compute addresses list --project concrete-detection-1-491711

   # Forwarding rules / target proxies / URL maps left by the L7 LB
   gcloud compute forwarding-rules list --project concrete-detection-1-491711
   gcloud compute target-http-proxies list --project concrete-detection-1-491711
   gcloud compute url-maps list --project concrete-detection-1-491711

   # Backend services and NEGs
   gcloud compute backend-services list --project concrete-detection-1-491711
   gcloud compute network-endpoint-groups list --project concrete-detection-1-491711

   # Persistent disks
   gcloud compute disks list --project concrete-detection-1-491711

   # GKE clusters (should be empty)
   gcloud container clusters list --project concrete-detection-1-491711
   ```

3. **Release a leaked static IP** if `terraform destroy` missed it:

   ```bash
   gcloud compute addresses delete concrete-detection-ip \
     --global --project concrete-detection-1-491711
   ```

4. **State bucket & DNS zone** are usually kept between runs. Delete only if you are
   fully decommissioning:

   ```bash
   gsutil rm -r gs://crack-detection-terraform        # destroys TF state — irreversible
   gcloud dns managed-zones delete concrete-zone-1 --project concrete-detection-1-491711
   ```

5. **NFS data** lives in `emptyDir` and is gone the moment the NFS pod dies — there is
   nothing to clean up, but also nothing to recover. Don't rely on it for anything
   you need to keep.
