# CLAUDE.md

Context for working in this repo. This is a **platform/infra** project, not an app-feature project — most work here is on Helm charts, Terraform, GitHub Actions workflows, and shell/Ansible glue.

## What this is

A 3-component "concrete crack detection" demo app, used as a vehicle to practice cloud platform engineering. The app itself is incidental; the value is the deploy infrastructure across **GCP (GKE)** and **DigitalOcean (DOKS)**.

The three app components (built into Docker images, pushed to DockerHub under `maheshrajannan/`):
1. `image-upload-logic` — React/Node web app, uploads concrete photos (port 8080)
2. `crack-detection-logic` — Python OpenCV app, finds cracks, renames `x.png` → `x-processed.png` (port 8081, internal ClusterIP only)
3. `concrete-image-gallery-logic` — Node/Express + Pug, displays original vs processed images (port 8082)

All three share one NFS-backed PVC (`concrete-images-pvc-nfs`). Flow: upload pod writes images → crack-detection pod processes them → gallery pod serves them.

## Repo layout

| Path | What it is |
|---|---|
| `buildConcreteDetection/` | Source + Dockerfiles + build scripts for the 3 app components (`imageUpload/`, `crackDetection/`, `concreteImageGallery/`, plus `local*` variants) |
| `masterChart/` | Umbrella Helm chart. Subcharts in `charts/`: `pv-chart`, `image-upload`, `crack-detection`, `concrete-image-gallery`, and `ingressChart` |
| `nfsServerChart/` | Standalone Helm chart for the in-cluster NFS server |
| `clusterPersistentDisk/` | Cluster + persistent disk setup scripts |
| `terraform/` | IaC. Variants: `gcp/`, `gcp-mahesh/`, `gcp-bootstrap/`, `gcp-bootstrap-mahesh/`, `digitalocean/`, `digitalocean-mahesh/` |
| `ansible/` | `deploy-master-chart.yml` — modern replacement for `populateCIP.py` + Helm portion of `runHelmCharts.sh` |
| `.github/workflows/` | ~20 GHA workflows. `Mahesh-*` are the user's active/canonical ones; non-prefixed are older/shared variants |
| `*.md` (root) | Topic docs: `platform-architecture.md` (authoritative arch ref), `argo.md`, `chartmuseum.md`, `litmuschaos*.md`, `certificate.md`, `cost-estimate.md`, `ansible.md`, `gCloudDockerSetup.md` |
| `docScreenshots/` | Images for the docs |
| `keys/` | Credentials — **gitignored, never commit** |

## Architecture (GKE prod path)

`platform-architecture.md` is the source of truth (has full mermaid sequence/system diagrams). Summary:

- **Terraform** provisions GKE cluster `crack-detection-cluster` (us-central1-a), node pool `primary-node-pool` (e2-medium, 3–7 nodes), TF state in GCS bucket `crack-detection-terraform`.
- **Deploy workflow** reserves global static IP `concrete-detection-ip`, installs NFS chart, discovers its ClusterIP, installs master chart, creates `ManagedCertificate` + GCE Ingress.
- **GCE Ingress** auto-provisions an L7 load balancer; routes `/` → gallery :8082, `/upload /uploaded` → upload :8080.
- **DNS/SSL**: domain `maheshconcretegallery.online` registered at Hostinger, NS delegated to GCP Cloud DNS zone `concrete-zone-1`; A record → static IP; GCP Managed Certificate `concrete-gallery-cert` does HTTP-01 validation.

## Key gotchas (likely sources of defects)

- **GCE Ingress requires `NodePort` services** — a `ClusterIP` service will break load-balancer backend sync. `crack-detection-svc` is deliberately ClusterIP because it's internal-only (no ingress path).
- **NFS server uses `emptyDir`**, not a persistent disk — uploaded images are **lost if the NFS pod restarts**.
- **NFS ClusterIP injection**: the PV needs the NFS service ClusterIP. Three mechanisms exist, in order of currency:
  1. `populateCIP.py` — **unused/legacy**, mutates `masterChart/charts/pv-chart/values.yaml` on disk (kept for reference only).
  2. `runHelmCharts.sh` — still calls `populateCIP.py` then `helm install`.
  3. `ansible/deploy-master-chart.yml` — **preferred**, discovers ClusterIP at deploy time and injects inline (`pv-chart.nfsCIP`), no file mutation.
- **`masterChart/Chart.yaml` lists only 4 deps** (`pv-chart`, `image-upload`, `crack-detection`, `concrete-image-gallery`) — `ingressChart` lives under `charts/` but is NOT wired as a dependency there; treat it as separately managed.
- Apex domain `concretecrackgallery.online` → `34.8.140.102` is a **different, unmanaged** IP — not part of this stack.
- Many parallel `Mahesh-*` vs non-prefixed workflows/terraform dirs exist. When fixing something, confirm **which variant** is actually in use before editing.

## Known issues & fixes (learned)

- **Cluster name was hardcoded** in `terraform/gcp-mahesh/main.tf` (`name = "crack-detection-cluster"`), and `Mahesh-Cluster.yaml` had no `cluster_name` input — so any value "passed" for the cluster name was silently ignored. **Fixed**: added a `cluster_name` TF variable (`name = var.cluster_name`, default `crack-detection-cluster`), a `cluster_name` workflow_dispatch input, and `TF_VAR_cluster_name` env wiring; also de-hardcoded the two connect-command echo lines. Notes: the cluster `name` is force-new — changing it against existing state destroys + recreates the cluster, it does not rename. The `TF_VAR_cluster_name` env is also visible to the DO steps but harmlessly ignored (no such var in the DO module). The non-mahesh `terraform/gcp/` module likely still has the same hardcoding if that path is used.
- **mkcert + `JAVA_HOME` failure**: on the workstation, `mkcert <domain>` aborts with `failed to execute "keytool -list" ... Keystore file does not exist`. Cause: mkcert probes the Java trust store at startup (`JAVA_HOME` set, or a `keytool` on PATH pointing at a broken/removed JDK whose `cacerts` is missing). Workaround: prefix the command with `JAVA_HOME=` (e.g. `JAVA_HOME= mkcert <domain>`) to skip the Java store, or `unset JAVA_HOME`. Same applies to `mkcert -install`. The root CA must be installed once (`mkcert -install`) for browser trust, but for generating K8s TLS-secret cert/key files that step isn't required.
- **mkcert certs are not publicly trusted** — fine for local/in-cluster testing, not for the public ingress. Public domains (`*.concretecrackgallery.*`, `maheshconcretegallery.online`) need a real CA (GCP Managed Certificate / Let's Encrypt via cert-manager).

## Conventions

- Image refs come from `masterChart/values.yaml` `global.*Image` keys (currently `:latest` tags).
- Two clouds: GCP (GKE, primary, SSL path) and DigitalOcean (DOKS, secondary). Workflows and terraform dirs are split accordingly.
- Secrets are GitHub Actions secrets (e.g. `MAHESH_GCP_CD_2_SA_KEY`); local creds go in `keys/` (gitignored).

## When helping with defects

1. Identify the layer: app code (`buildConcreteDetection/`), Helm template (`masterChart/charts/*/templates/`), Terraform, or workflow (`.github/workflows/`).
2. Confirm the active variant (`Mahesh-*` workflow / `*-mahesh` terraform dir vs the generic one).
3. Cross-check against `platform-architecture.md` for expected resource names, ports, and routing.
4. Validate Helm changes with `helm template`/`helm lint` and Terraform with `terraform validate` / `plan` before suggesting apply.
