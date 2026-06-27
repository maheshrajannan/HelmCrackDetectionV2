# Terraform Backend: Externalize the State Bucket

**Issue (High · terraform):** The `backend` block is parsed before variables exist, so
`bucket` must be a literal. These literals are globally-unique names already owned by
this project, so a fresh account has to hand-edit four files just to run `init`.

| File | Current literal |
|---|---|
| `terraform/gcp-mahesh/backend.tf:3` | `crack-detection-terraform` |
| `terraform/gcp-bootstrap-mahesh/main.tf:3` | `crack-detection-terraform` |
| `terraform/gcp/backend.tf:3` | `crack-detection-terraform-1` |
| `terraform/gcp-bootstrap/main.tf:3` | `crack-detection-terraform-1` |
| `terraform/digitalocean-mahesh/main.tf:6` | `terraform-crack-detection-1` |
| `terraform/digitalocean/main.tf:6` | `terraform-crack-detection` |

**Recommended approach:** *partial backend configuration* — strip the account-specific
value out of the committed `.tf` and supply it at `terraform init` time via
`-backend-config`. The DO modules already do this for credentials
(`-backend-config="access_key=..."`); this just extends the same pattern to `bucket`.

---

## Step 1 — Smallest incremental fix (do this first, then test)

Change **only** the canonical active GCP module: `terraform/gcp-mahesh/`.
Leave every other module untouched until this is verified.

### 1a. Make the backend block partial

`terraform/gcp-mahesh/backend.tf`

```hcl
terraform {
  backend "gcs" {
    prefix = "gke/terraform"   # not globally unique — safe to keep committed
    # bucket is supplied at init time via -backend-config
  }
}
```

### 1b. Add an example backend config (committed) + a real one (gitignored)

`terraform/gcp-mahesh/backend.hcl.example`

```hcl
# Copy to backend.hcl and set your own globally-unique GCS bucket.
# The bucket must already exist before `terraform init`.
bucket = "REPLACE_WITH_YOUR_TFSTATE_BUCKET"
```

Add to `.gitignore`:

```
backend.hcl
```

### 1c. Initialize with it

```bash
cd terraform/gcp-mahesh
cp backend.hcl.example backend.hcl   # then edit backend.hcl
terraform init -backend-config=backend.hcl

# or inline, no file:
terraform init -backend-config="bucket=$TF_STATE_BUCKET"
```

> **Prerequisite:** the GCS bucket must exist *before* `init` — a backend cannot create
> its own bucket. Create it once: `gcloud storage buckets create gs://$TF_STATE_BUCKET`.

### 1d. (Optional, same step) Wire the workflow

If you deploy `gcp-mahesh` via a workflow, change its bare `terraform init` to pass the
bucket from a `workflow_dispatch` input or repo variable, e.g.:

```yaml
- name: Terraform Init
  run: terraform init -input=false -backend-config="bucket=${{ vars.TF_STATE_BUCKET }}"
```

### How to test Step 1

1. `terraform init -backend-config=backend.hcl` succeeds and reports the GCS backend.
2. `terraform plan` runs and reads/writes state in your bucket.
3. Confirm no diff to state behavior vs. before (same `prefix = gke/terraform`, so the
   existing state object is found — only the bucket source changed).

---

## Step 2 — Roll out to remaining modules (after Step 1 is verified)

Apply the identical pattern to each, keeping non-unique keys committed:

- `gcp/backend.tf` and `gcp-bootstrap/main.tf` — remove `bucket`, keep `prefix`.
- `gcp-bootstrap-mahesh/main.tf` — remove `bucket`, keep `prefix`.
- `digitalocean/main.tf` and `digitalocean-mahesh/main.tf` — remove `bucket`
  (keep `endpoints`, `region`, `key`, `skip_*`; creds already externalized).

Each gets its own `backend.hcl.example`. Update the corresponding workflow `init` calls
to pass `-backend-config="bucket=..."`.

## Step 3 — Document the bootstrap ordering

The `gcp-bootstrap*` modules are what create the bucket, but they also declare a GCS
backend → chicken-and-egg. Document that the very first run uses a local backend:

```bash
cd terraform/gcp-bootstrap-mahesh
terraform init -backend=false   # local state for the first apply
terraform apply                 # creates the GCS bucket
# then migrate: terraform init -backend-config=backend.hcl -migrate-state
```

Add this to the repo setup docs so a fresh account has a clear path:
create bucket (bootstrap, local backend) → migrate state → init main modules against it.

---

## Notes

- Only `bucket` (and DO creds) must be externalized; `prefix`/`key` are not globally
  unique, so keeping them committed minimizes what each user configures.
- `-backend-config` accepts either a file (`=backend.hcl`) or repeated inline
  `key=value` flags — use the file locally, inline flags in CI.
