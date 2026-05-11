# Creating and Running Your First Chaos Experiment with LitmusChaos

> **Video Reference:** [Creating and Run Your First Chaos Experiment with LitmusChaos | Chaos Engineering](https://youtu.be/ouxL78-rFNw?si=e3ml-pbu7UASxgJ2)  
> **LitmusChaos Docs:** [https://docs.litmuschaos.io](https://docs.litmuschaos.io)  
> **Version:** LitmusChaos 3.x (ChaosCenter)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Understanding a Chaos Experiment](#3-understanding-a-chaos-experiment)
4. [Designing a Chaos Workflow](#4-designing-a-chaos-workflow)
5. [Step-by-Step: Creating Your First Experiment](#5-step-by-step-creating-your-first-experiment)
   - [Step 1 — Open the Chaos Studio](#step-1--open-the-chaos-studio)
   - [Step 2 — Name Your Experiment](#step-2--name-your-experiment)
   - [Step 3 — Select Target Chaos Infrastructure](#step-3--select-target-chaos-infrastructure)
   - [Step 4 — Choose Your Build Method](#step-4--choose-your-build-method)
   - [Step 5 — Add a Fault](#step-5--add-a-fault)
   - [Step 6 — Tune the Fault](#step-6--tune-the-fault)
   - [Step 7 — Add a Resilience Probe](#step-7--add-a-resilience-probe)
   - [Step 8 — Set Fault Weightage](#step-8--set-fault-weightage)
   - [Step 9 — Save and Run the Experiment](#step-9--save-and-run-the-experiment)
6. [Observing the Experiment](#6-observing-the-experiment)
7. [Analyzing Results & Resilience Score](#7-analyzing-results--resilience-score)
8. [Scheduling Recurring Experiments](#8-scheduling-recurring-experiments)
9. [Sample Chaos Experiment YAML](#9-sample-chaos-experiment-yaml)
10. [Summary](#10-summary)
11. [References](#11-references)

---

## 1. Overview

This guide walks you through creating and running your **first Chaos Experiment** using **LitmusChaos ChaosCenter** — the web-based control plane for designing, scheduling, and observing chaos experiments on Kubernetes clusters.

By the end of this guide you will be able to:

- Design a chaos workflow with one or more faults
- Attach resilience probes for automated hypothesis validation
- Run the experiment on your cluster
- Observe real-time execution and interpret results

> 💡 **Terminology Note (LitmusChaos 3.x):**  
> - **Chaos Fault** = previously called *Chaos Experiment*  
> - **Chaos Experiment** = previously called *Chaos Scenario/Workflow*

---

## 2. Prerequisites

Before you begin, ensure the following are in place:

| Requirement | Description |
|---|---|
| **LitmusChaos ChaosCenter** | Installed and accessible (v3.x recommended) |
| **Chaos Infrastructure** | At least one connected infrastructure (Kubernetes agent) |
| **Target Application** | A running workload (e.g., an nginx deployment) to experiment on |
| **Resilience Probe** *(optional)* | Pre-created probe to validate the hypothesis (see [Probes Guide](./litmuschaos-probes-documentation.md)) |

---

## 3. Understanding a Chaos Experiment

A **Chaos Experiment** in LitmusChaos is a combination of ordered steps that simulate real-world failure scenarios. It is powered by **Argo Workflows** under the hood and is fully declarative.

### Key Concepts

```
Chaos Experiment
    └── Fault 1  ──── ChaosEngine ──── Probes
    └── Fault 2  ──── ChaosEngine ──── Probes
    └── Revert Chaos Step
```

| Concept | Description |
|---|---|
| **Chaos Fault** | A specific failure injection (e.g., pod-delete, network-loss) |
| **ChaosEngine** | Kubernetes CR that links an experiment to a target app |
| **Probe** | Automated health check run before/during/after chaos |
| **Resilience Score** | Calculated score (0–100) based on probe results and fault weights |

### Chaos Experiment Lifecycle

```
Install Fault → Execute ChaosEngine → Validate Probes → Revert Chaos → Generate ChaosResult
```

---

## 4. Designing a Chaos Workflow

Before clicking any buttons, think through these three questions:

1. **What is your Steady State?** — What does "healthy" look like? (e.g., HTTP 200 from your service, all pods running)
2. **What failure scenario do you want to test?** — (e.g., pod deletion, CPU stress, network latency)
3. **What do you expect to happen?** — (e.g., service remains available during pod churn due to replica sets)

A good chaos experiment tests a specific hypothesis: *"When X happens, our system still achieves Y."*

---

## 5. Step-by-Step: Creating Your First Experiment

### Step 1 — Open the Chaos Studio

From the **ChaosCenter home page**, click the **"Schedule a chaos scenario"** button, or navigate to **Chaos Experiments → Schedule Chaos Scenario**.

![Home Page - Schedule Chaos Scenario](https://docs.litmuschaos.io/assets/images/new-experiment-overview-home-9803294db8b6cd9c355102e0912f8649.png)

This opens the **Chaos Studio** — the visual editor for building experiments.

---

### Step 2 — Name Your Experiment

In the **Experiment Overview** panel, fill in:

- **Name** *(required)* — e.g., `pod-delete-nginx-test`
- **Description** *(optional)* — e.g., "Tests nginx resilience under pod deletion"
- **Tags** *(optional)* — e.g., `nginx`, `pod-level`, `staging`

![Add Experiment Identifiers](https://docs.litmuschaos.io/assets/images/new-experiment-identifiers-f843b5d8cd2bd0a4cc7495a23647f315.png)

Click **Next** to proceed.

---

### Step 3 — Select Target Chaos Infrastructure

Choose the **Chaos Infrastructure** (the Kubernetes agent) where your target application is running. Click **Apply** to confirm, then **Next**.

![Select Chaos Infrastructure](https://docs.litmuschaos.io/assets/images/new-experiment-infra-select-99524d285432a7dcdf253d9577ed68d0.png)

> 💡 If no infrastructure appears, you need to connect one first. See the [Chaos Infrastructure setup guide](https://docs.litmuschaos.io/docs/user-guides/create-infrastructure).

---

### Step 4 — Choose Your Build Method

You will be asked how to build the experiment. Three options are available:

![Choose Experiment Build Method](https://docs.litmuschaos.io/assets/images/new-experiment-choose-method-c89665e57709cde57b444e8a166e8c09.png)

| Option | When to Use |
|---|---|
| **Blank Canvas** | Build from scratch — choose specific faults manually |
| **Templates from Chaos Hubs** | Use pre-built experiment templates from ChaosHub |
| **Upload YAML** | Import an existing experiment manifest file |

For this guide, select **Blank Canvas**.

![Blank Canvas View](https://docs.litmuschaos.io/assets/images/new-experiment-blank-canvas-e5cdf8177258f149b52ec56963414307.png)

---

### Step 5 — Add a Fault

Click **"Add"** in the experiment builder. A panel will open listing all available faults from the connected **ChaosHub**.

![LitmusChaos ChaosHub Fault List](https://docs.litmuschaos.io/assets/images/litmus-chaos-hub-50d8b477f28d4a38a1c1e95cf0c51c3f.png)

Browse or search for the fault you want. For a first experiment, **`pod-delete`** is a great starting point — it deletes one or more pods to validate your application's ability to self-heal.

Click on the fault to add it to your experiment canvas.

> 💡 **Parallel Faults:** To run two faults in parallel, hover below an existing fault block and click **Add**. Faults stacked vertically run in parallel; fault groups arranged left-to-right run in sequence.

![Add Parallel Faults](https://docs.litmuschaos.io/assets/images/add-parallel-faults-e3231592346c83749ba6c60f73af474a.png)

---

### Step 6 — Tune the Fault

After adding the fault, click on it to open the **tuning panel**.

![Tune Fault Panel](https://docs.litmuschaos.io/assets/images/tune-fault-81d0adbba46f12ef887903a9a14f61b0.png)

You will configure three sub-sections:

#### a) Target Application *(Pod-level faults only)*

Specify which application pods to target:

| Field | Example Value | Description |
|---|---|---|
| `appns` | `default` | Namespace of the target app |
| `applabel` | `app=nginx` | Label selector for the target pods |
| `appkind` | `deployment` | Kubernetes resource kind |

#### b) Fault Parameters

Common parameters shared by most faults:

| Parameter | Example | Description |
|---|---|---|
| `TOTAL_CHAOS_DURATION` | `30` | Duration of chaos in seconds |
| `CHAOS_INTERVAL` | `10` | Interval between successive fault actions |
| `FORCE` | `false` | Force-delete pods (bypasses graceful termination) |
| `PODS_AFFECTED_PERC` | `50` | Percentage of matching pods to target |
| `RAMP_TIME` | `0` | Wait time before and after chaos |

#### c) Advanced Options *(Optional)*

Access via **Advanced Options** on the builder tab:

![Advanced Options](https://docs.litmuschaos.io/assets/images/advanced-options-experiment-creation-0c4848a3768b8c140bfb6303328c0b4b.png)

- **Node Selector** — Restrict experiment pods to specific nodes (key-value label pairs)
- **Tolerations** — Allow scheduling on tainted nodes

![Node Selectors](https://docs.litmuschaos.io/assets/images/node-selectors-ec00766e6dc3dd8620234d81457bca93.png)

![Tolerations](https://docs.litmuschaos.io/assets/images/tolerations-fcd4e5ff80c9361e4820ec15cb427487.png)

---

### Step 7 — Add a Resilience Probe

Navigate to the **Probes** tab within the fault tuning panel. Probes are automated checks that validate your chaos hypothesis during the experiment.

You can either:
- **Select an existing probe** from the Resilience Probes library
- **Create a new probe** inline

> 📖 For detailed probe creation steps, refer to the [Creating Probes in LitmusChaos Guide](./litmuschaos-probes-documentation.md).

**Example: HTTP Probe for pod-delete**

This probe continuously checks that your service URL returns HTTP 200 — even while pods are being deleted:

```yaml
probe:
  - name: 'check-nginx-availability'
    type: 'httpProbe'
    httpProbe/inputs:
      url: 'http://nginx-service.default.svc.cluster.local/health'
      insecureSkipVerify: false
      responseTimeout: 500
      method:
        get:
          criteria: ==
          responseCode: '200'
    mode: 'Continuous'
    runProperties:
      probeTimeout: 5s
      interval: 2s
      retry: 1
      probePollingInterval: 2s
```

| Probe Mode | Best Used With |
|---|---|
| `Continuous` | HTTP probes — live availability check during chaos |
| `Edge` | CMD / K8s probes — check state before and after |
| `EOT` | K8s probes — verify recovery post-chaos |

---

### Step 8 — Set Fault Weightage

Each fault in the experiment has a **weight (1–10)** that determines its contribution to the overall **Resilience Score**.

| Weight Range | Priority |
|---|---|
| 0 – 3 | Low Priority |
| 4 – 6 | Medium Priority |
| 7 – 10 | High Priority |

Set the weight based on how critical this fault is to your system's overall resilience evaluation.

---

### Step 9 — Save and Run the Experiment

Once all faults are configured, click the **Save** button.

![Save Chaos Experiment](https://docs.litmuschaos.io/assets/images/chaos-experiment-save-e182e43ee936c7f5d65cf2ae322a9b3f.png)

You now have two options:

- **Run** — Execute the experiment immediately
- **Schedule** — Set up a recurring cron schedule (hourly, daily, weekly, monthly)

For your first run, click **Run** to execute immediately.

---

## 6. Observing the Experiment

Once the experiment is running, you can observe it in real time from ChaosCenter.

### Accessing the Live View

Navigate to the **Chaos Experiments** page. From the experiment's heatmap, click on the running experiment run box to open the execution view.

![Select Experiment Run from Heatmap](https://docs.litmuschaos.io/assets/images/workflow-observe-select-ba1acdaeeb1465183b436b912d41d1df.png)

### Real-Time Execution Graph

A live DAG (Directed Acyclic Graph) displays all steps of the experiment and their current status.

![Real-time Experiment Graph](https://docs.litmuschaos.io/assets/images/workflow-observe-running-04cecd8989f419872600324922dd4c69.png)

**Node status indicators:**

| Color / Status | Meaning |
|---|---|
| 🔵 Running | Step is currently executing |
| ✅ Succeeded | Step completed successfully |
| ❌ Failed | Step failed |
| ⏸ Pending | Step is waiting to start |

### Viewing Step Logs

Click any node in the graph to open the **details pane** on the right side. You can view:
- Node details and status
- Real-time pod logs
- Probe results (once execution completes)

![Experiment Step Logs](https://docs.litmuschaos.io/assets/images/workflow-observe-log-36076db176a871076da1e4e5c4e654a2.png)

### Completed Experiment View

Once the experiment finishes, the graph will show the final status of all steps, along with the **ChaosResult** for each fault.

![Completed Experiment View](https://docs.litmuschaos.io/assets/images/workflow-observe-completed-555d518b1d31b54a59f069cd42020335.png)

---

## 7. Analyzing Results & Resilience Score

### Resilience Score Formula

After execution, LitmusChaos calculates a **Resilience Score** (0–100):

```
Fault Resilience = Weight × Probe Success Percentage
Overall Resilience Score = Sum(Fault Resilience) / Sum(All Fault Weights) × 100
```

**Example:**

| Fault | Weight | Probe Success % | Fault Score |
|---|---|---|---|
| pod-delete | 8 | 100% | 800 |
| cpu-hog | 5 | 80% | 400 |
| **Total** | **13** | — | **1200** |

```
Resilience Score = 1200 / 1300 × 100 = 92.3
```

### Reading ChaosResult

After the experiment, inspect the `ChaosResult` CR to see detailed probe outcomes:

```yaml
Status:
  Experimentstatus:
    Phase: Completed
    Probe Success Percentage: 100
    Verdict: Pass

  Probe Status:
    - Name: check-nginx-availability
      Status:
        Continuous: Passed 👍
      Type: HTTPProbe
```

**Verdict outcomes:**

| Verdict | Meaning |
|---|---|
| `Pass` | All probes succeeded; experiment hypothesis validated |
| `Fail` | One or more probes failed; resilience gap identified |
| `Awaited` | Experiment is still running |
| `Stopped` | Experiment was manually stopped |

---

## 8. Scheduling Recurring Experiments

To schedule the experiment to run periodically, use the **Schedule** tab when saving:

| Option | Cron Equivalent |
|---|---|
| Every Hour | `0 * * * *` |
| Every Day | `0 0 * * *` |
| Every Week | `0 0 * * 0` |
| Every Month | `0 0 1 * *` |

A scheduled experiment becomes a **Cron Chaos Experiment** — a `CronWorkflow` resource managed by Argo.

```yaml
# Example cron chaos experiment schedule
spec:
  schedule: "10 0-23 * * *"    # runs at the 10th minute of every hour
  concurrencyPolicy: Forbid
```

---

## 9. Sample Chaos Experiment YAML

This is the complete YAML structure of a `pod-delete` chaos experiment, showing how faults, probes, and steps are composed together:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: pod-delete-nginx-test
  namespace: litmus
  labels:
    subject: pod-delete-nginx-test_litmus
spec:
  arguments:
    parameters:
      - name: adminModeNamespace
        value: litmus
  entrypoint: custom-chaos
  serviceAccountName: argo-chaos
  templates:
    # ── Orchestration steps ──────────────────────────────────────────
    - name: custom-chaos
      steps:
        - - name: install-chaos-faults
            template: install-chaos-faults
        - - name: pod-delete
            template: pod-delete
        - - name: revert-chaos
            template: revert-chaos

    # ── Install the ChaosExperiment CR ──────────────────────────────
    - name: install-chaos-faults
      container:
        image: litmuschaos/k8s:latest
        command: [sh, -c]
        args:
          - kubectl apply -f https://hub.litmuschaos.io/api/chaos/3.0.0?file=charts/generic/pod-delete/experiment.yaml
            -n {{workflow.parameters.adminModeNamespace}} | sleep 30

    # ── Execute the fault with a probe ──────────────────────────────
    - name: pod-delete
      inputs:
        artifacts:
          - name: pod-delete
            path: /tmp/chaosengine-pod-delete.yaml
            raw:
              data: |
                apiVersion: litmuschaos.io/v1alpha1
                kind: ChaosEngine
                metadata:
                  namespace: "{{workflow.parameters.adminModeNamespace}}"
                  generateName: pod-delete
                spec:
                  appinfo:
                    appns: default
                    applabel: app=nginx
                    appkind: deployment
                  engineState: active
                  chaosServiceAccount: litmus-admin
                  jobCleanUpPolicy: retain
                  experiments:
                    - name: pod-delete
                      spec:
                        probe:
                          - name: 'check-nginx-availability'
                            type: 'httpProbe'
                            httpProbe/inputs:
                              url: 'http://nginx-service.default.svc.cluster.local'
                              insecureSkipVerify: false
                              method:
                                get:
                                  criteria: ==
                                  responseCode: '200'
                            mode: 'Continuous'
                            runProperties:
                              probeTimeout: 5s
                              interval: 2s
                              retry: 1
                              probePollingInterval: 2s
                        components:
                          env:
                            - name: TOTAL_CHAOS_DURATION
                              value: "30"
                            - name: CHAOS_INTERVAL
                              value: "10"
                            - name: FORCE
                              value: "false"
                            - name: PODS_AFFECTED_PERC
                              value: "50"
      container:
        image: litmuschaos/litmus-checker:latest
        args:
          - -file=/tmp/chaosengine-pod-delete.yaml
          - -saveName=/tmp/engine-name

    # ── Cleanup chaos resources ──────────────────────────────────────
    - name: revert-chaos
      container:
        image: litmuschaos/k8s:latest
        command: [sh, -c]
        args:
          - kubectl delete chaosengine -l 'instance_id in (pod-delete)' -n
            {{workflow.parameters.adminModeNamespace}}
  podGC:
    strategy: OnWorkflowCompletion
```

---

## 10. Summary

| Phase | What Happens |
|---|---|
| **Design** | Define hypothesis, choose faults, set targets and parameters |
| **Probe Setup** | Add HTTP/CMD/K8s/Prometheus probes for automated validation |
| **Run** | Execute the experiment — Argo Workflow orchestrates fault injection |
| **Observe** | Real-time DAG view with live logs and step statuses in ChaosCenter |
| **Analyze** | Review ChaosResult, probe outcomes, and Resilience Score |
| **Schedule** | Optionally set up recurring cron experiments |

**Resilience Score interpretation:**

| Score | Interpretation |
|---|---|
| 90 – 100 | Highly resilient system |
| 70 – 89 | Good resilience, minor gaps |
| 50 – 69 | Moderate resilience, improvements needed |
| Below 50 | Significant reliability concerns |

---

## 11. References

| Resource | Link |
|---|---|
| 📹 Video Tutorial | [Creating and Run Your First Chaos Experiment](https://youtu.be/ouxL78-rFNw?si=e3ml-pbu7UASxgJ2) |
| 📄 Probes Guide | [Creating Probes in LitmusChaos](https://youtu.be/CdL8kI7dGCo?si=0Uej1zDHJYo3RAOh) |
| 📄 Chaos Experiment Concept | [docs.litmuschaos.io/docs/concepts/chaos-workflow](https://docs.litmuschaos.io/docs/concepts/chaos-workflow) |
| 📄 Schedule Experiment Guide | [docs.litmuschaos.io/docs/user-guides/schedule-experiment](https://docs.litmuschaos.io/docs/user-guides/schedule-experiment) |
| 📄 Observe Experiment Guide | [docs.litmuschaos.io/docs/user-guides/observe-experiment](https://docs.litmuschaos.io/docs/user-guides/observe-experiment) |
| 📄 Resilience Probes Concept | [docs.litmuschaos.io/docs/concepts/probes](https://docs.litmuschaos.io/docs/concepts/probes) |
| 🐙 GitHub | [github.com/litmuschaos/litmus](https://github.com/litmuschaos/litmus) |
| 💬 Slack Community | [slack.litmuschaos.io](https://slack.litmuschaos.io) |