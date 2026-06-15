# Ansible in This Project

Ansible playbooks live in [`ansible/`](ansible/). The first demo,
[`deploy-master-chart.yml`](ansible/deploy-master-chart.yml), replaces the
(now unused) `populateCIP.py` and the Helm portion of `runHelmCharts.sh`:
it installs the nfs-server chart, looks up the NFS service ClusterIP via the
Kubernetes API, and injects it inline into the master chart install — no
file mutation, no `sleep`, fully idempotent and re-runnable.

## Getting Started

1. **Install Ansible and the Kubernetes Python client** (on your workstation):

   ```bash
   pip3 install ansible kubernetes
   ```

2. **Install the required Ansible collection:**

   ```bash
   ansible-galaxy collection install kubernetes.core
   ```

3. **Point kubectl at your cluster** (the playbook uses your current
   kubeconfig context, same as kubectl/helm):

   ```bash
   gcloud container clusters get-credentials <cluster-name> --zone <zone>
   kubectl config current-context   # verify
   ```

4. **Run the playbook** from the repo root:

   ```bash
   ansible-playbook ansible/deploy-master-chart.yml
   ```

   Re-running it is safe: Ansible checks the state of each Helm release and
   only changes what's needed. To tear down:

   ```bash
   helm uninstall master-chart nfs-server
   ```

   Note: Docker image builds (the first half of `runHelmCharts.sh`) are not
   covered by this playbook yet — see use case 2 below.

## Other Ansible Use Cases for This Project

1. **Replace the bash glue scripts entirely.** `runHelmCharts.sh` and
   `runLitmusChaos.sh` are sequential and not idempotent — a failure halfway
   leaves manual cleanup. Porting them to playbooks with `kubernetes.core.helm`
   and `kubernetes.core.k8s` makes every deploy re-runnable and self-checking.

2. **Image build & push automation.** Wrap the three `build*Image.sh` scripts
   (image-upload, crack-detection, concrete-image-gallery) in a playbook using
   `community.docker.docker_image`, with tags as variables instead of
   hard-coded `latest`.

3. **Workstation bootstrap.** Turn the manual steps in `gCloudDockerSetup.md`
   into a one-command playbook that installs gcloud, Docker, kubectl, Helm,
   Terraform, and Terragrunt — ideal for the student/newbie audience of this
   repo.

4. **End-to-end pipeline orchestration.** A single playbook chaining:
   Terragrunt apply → fetch GKE credentials → build/push images → deploy
   charts → run LitmusChaos probes and assert on results. Cleaner ordering,
   retries, and failure handling than chained shell scripts.

5. **LitmusChaos experiment automation.** Apply chaos experiments with
   `kubernetes.core.k8s`, poll the ChaosResult CRD with `k8s_info` + `until`,
   and fail the play if the resiliency probe fails — chaos testing as a
   repeatable gate instead of a manual run.

6. **Secrets with ansible-vault.** Encrypt the service-account keys and
   certificates in `keys/` with `ansible-vault` instead of keeping them in
   plaintext on disk.

7. **Multi-environment promotion.** As the Terragrunt setup grows into
   dev/qa/prod, Ansible inventory groups + `group_vars` let one playbook
   deploy any environment with per-env values (cluster name, namespace,
   image tags).
