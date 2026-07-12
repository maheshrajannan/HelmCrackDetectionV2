# Publishing Helm Charts to a Hosted Registry

This guide covers pushing `masterChart` and `nfsServerChart` to a hosted OCI registry.
Two options are covered — **Docker Hub** (recommended, reuses existing credentials) and **GitHub Container Registry (GHCR)**.

---

## Prerequisites

Helm 3.8+ is required for OCI support.

```bash
helm version
# version.BuildInfo{Version:"v3.8.0", ...}
```

Enable OCI support if not already on (older Helm 3.x versions):

```bash
export HELM_EXPERIMENTAL_OCI=1
```

---

## Option 1 — Docker Hub (Recommended)

You already have Docker Hub credentials stored as GitHub Actions secrets (`MAHESH_DOCKER_USERNAME` / `MAHESH_DOCKER_PASSWORD`). No new accounts or secrets needed.

### Login

```bash
helm registry login registry-1.docker.io \
  --username <MAHESH_DOCKER_USERNAME> \
  --password <MAHESH_DOCKER_PASSWORD>
```

### Package the charts

```bash
# Package nfsServerChart
helm package ./nfsServerChart
# Produces: nfsServerChart-0.1.0.tgz

# Build sub-chart dependencies, then package masterChart
helm dependency build ./masterChart
helm package ./masterChart
# Produces: masterChart-0.1.0.tgz
```

### Push to Docker Hub

```bash
helm push nfsServerChart-0.1.0.tgz oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>
helm push masterChart-0.1.0.tgz oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>
```

Charts are published at:
- `oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>/nfsserverchart`
- `oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>/masterchart`

> Docker Hub lowercases chart names automatically.

### Verify

```bash
helm show chart oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>/masterchart --version 0.1.0
```

### Install from Docker Hub

```bash
# Instead of: helm upgrade --install nfs-server ./nfsServerChart
helm upgrade --install nfs-server \
  oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>/nfsserverchart \
  --version 0.1.0

# Instead of: helm upgrade --install master-chart ./masterChart
helm upgrade --install master-chart \
  oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>/masterchart \
  --version 0.1.0
```

---

## Option 2 — GitHub Container Registry (GHCR)

Use this if you prefer to keep charts alongside the source code in GitHub.

### Generate a GitHub Personal Access Token (PAT)

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Grant `write:packages` and `read:packages` scopes
3. Save the token

### Login

```bash
helm registry login ghcr.io \
  --username <your-github-username> \
  --password <your-github-pat>
```

### Package the charts

```bash
helm package ./nfsServerChart
helm dependency build ./masterChart
helm package ./masterChart
```

### Push to GHCR

```bash
helm push nfsServerChart-0.1.0.tgz oci://ghcr.io/<your-github-username>
helm push masterChart-0.1.0.tgz oci://ghcr.io/<your-github-username>
```

Charts are published at:
- `oci://ghcr.io/<your-github-username>/nfsserverchart`
- `oci://ghcr.io/<your-github-username>/masterchart`

### Install from GHCR

```bash
helm upgrade --install nfs-server \
  oci://ghcr.io/<your-github-username>/nfsserverchart \
  --version 0.1.0

helm upgrade --install master-chart \
  oci://ghcr.io/<your-github-username>/masterchart \
  --version 0.1.0
```

---

## Updating a Chart

Bump the version in `Chart.yaml`, repackage, and push:

```bash
# Edit masterChart/Chart.yaml: version: 0.2.0
helm dependency build ./masterChart
helm package ./masterChart
helm push masterChart-0.2.0.tgz oci://registry-1.docker.io/<MAHESH_DOCKER_USERNAME>
```

---

## GitHub Actions Integration

Update `MAHESH_DEPLOY-SSL-GKE.yaml` to pull charts from Docker Hub instead of the local repo checkout.

Replace the Helm deploy step:

```yaml
- name: Deploy Application using Helm
  run: |
    helm registry login registry-1.docker.io \
      --username ${{ secrets.MAHESH_DOCKER_USERNAME }} \
      --password ${{ secrets.MAHESH_DOCKER_PASSWORD }}

    helm upgrade --install nfs-server \
      oci://registry-1.docker.io/${{ secrets.MAHESH_DOCKER_USERNAME }}/nfsserverchart \
      --version 0.1.0
    sleep 3

    python3 populateCIP.py
    sleep 3

    helm upgrade --install master-chart \
      oci://registry-1.docker.io/${{ secrets.MAHESH_DOCKER_USERNAME }}/masterchart \
      --version 0.1.0
    sleep 5
```

> With this approach the deploy workflow no longer needs to checkout the repo just to access chart files. The charts are versioned and independently deployable artifacts, just like the Docker images.

---

## Comparison

| | Docker Hub | GHCR |
|---|---|---|
| Credentials | Already in GitHub secrets | Needs new PAT |
| Free tier | 1 private repo, unlimited public | Free for public, included in GitHub plan for private |
| Best for | Reusing existing setup | Keeping everything in GitHub |
| Chart visibility | Public by default | Public by default |
