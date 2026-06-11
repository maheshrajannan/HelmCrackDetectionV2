# Terragrunt Basics: One Module, Two Environments (dev / qa)

The whole idea in one sentence: **write the Terraform once, feed it different values per environment.**

```mermaid
flowchart LR
    subgraph TF["✍️ You write ONCE"]
        BASE["base module<br/>terraform/gke/<br/>─────────────<br/>main.tf uses variables:<br/>var.cluster_name<br/>var.machine_type<br/>var.node_count"]
    end

    subgraph ENVS["📝 Per-env: ONLY values"]
        DEVV["live/dev/terragrunt.hcl<br/>─────────────<br/>cluster_name = my-app-dev<br/>machine_type = e2-medium<br/>node_count = 1"]
        QAV["live/qa/terragrunt.hcl<br/>─────────────<br/>cluster_name = my-app-qa<br/>machine_type = e2-standard-4<br/>node_count = 3"]
    end

    subgraph OUT["☁️ Result: two clusters"]
        DEVC["dev cluster<br/>small + cheap<br/>state: dev/"]
        QAC["qa cluster<br/>bigger<br/>state: qa/"]
    end

    DEVV -->|"inputs → variables"| BASE
    QAV -->|"inputs → variables"| BASE
    BASE --> DEVC
    BASE --> QAC

    style BASE fill:#e3f2fd,stroke:#1976d2
    style DEVV fill:#fff3e0,stroke:#ef6c00
    style QAV fill:#fff3e0,stroke:#ef6c00
    style DEVC fill:#e8f5e9,stroke:#388e3c
    style QAC fill:#e8f5e9,stroke:#388e3c
```

Same blue box, two orange value-files, two green clusters. That's Terragrunt.

## The files

```
terraform/gke/main.tf       # base module — written once
live/
  root.hcl                  # backend (state bucket) — written once
  dev/terragrunt.hcl        # dev values
  qa/terragrunt.hcl         # qa values
```

**Base module** — variables instead of hardcoded values:

```hcl
# terraform/gke/main.tf
variable "cluster_name" {}
variable "machine_type" {}
variable "node_count"   {}

resource "google_container_cluster" "this" {
  name               = var.cluster_name
  location           = "us-central1-a"
  initial_node_count = var.node_count
  node_config { machine_type = var.machine_type }
}
```

**Root** — state bucket, defined once; each env gets its own state folder automatically:

```hcl
# live/root.hcl
remote_state {
  backend  = "gcs"
  generate = { path = "backend.tf", if_exists = "overwrite" }
  config = {
    bucket = "my-terraform-state"
    prefix = path_relative_to_include()   # dev/ for dev, qa/ for qa
  }
}
```

**Environments** — identical shape, different values:

```hcl
# live/dev/terragrunt.hcl
include "root" { path = find_in_parent_folders("root.hcl") }
terraform { source = "${get_repo_root()}/terraform/gke" }

inputs = {
  cluster_name = "my-app-dev"
  machine_type = "e2-medium"      # small + cheap
  node_count   = 1
}
```

```hcl
# live/qa/terragrunt.hcl
include "root" { path = find_in_parent_folders("root.hcl") }
terraform { source = "${get_repo_root()}/terraform/gke" }

inputs = {
  cluster_name = "my-app-qa"
  machine_type = "e2-standard-4"  # bigger, prod-like
  node_count   = 3
}
```

## Running

```bash
cd live/dev && terragrunt apply    # dev cluster only
cd live/qa  && terragrunt apply    # qa cluster only
cd live     && terragrunt run-all apply   # both
```

## How a value reaches the cluster

```mermaid
flowchart LR
    A["inputs block<br/>node_count = 3"] --> B["variable<br/>var.node_count"] --> C["resource<br/>initial_node_count"] --> D["☁️ qa cluster<br/>3 nodes"]
```

`inputs` (Terragrunt) → `variable` (Terraform) → `resource` argument → cloud. Adding a third env (staging, prod) = one new folder with one new `inputs` block. Nothing else changes.

---

*In this repo:* the base module is `terraform/gcp-mahesh`, and `live/mahesh/` plays the role of one environment. See `terragrunt-getting-started.md` for the repo-specific setup.
