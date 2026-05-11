# Creating Probes in LitmusChaos — Complete Guide

> **Reference:** [Creating Probes in LitmusChaos | Chaos Engineering](https://youtu.be/CdL8kI7dGCo?si=0Uej1zDHJYo3RAOh)  
> **LitmusChaos Docs:** [https://docs.litmuschaos.io/docs/concepts/probes](https://docs.litmuschaos.io/docs/concepts/probes)

---

## Table of Contents

1. [What are Resilience Probes?](#1-what-are-resilience-probes)
2. [Types of Probes](#2-types-of-probes)
3. [Probe Execution Modes](#3-probe-execution-modes)
4. [Creating a Probe via ChaosCenter UI](#4-creating-a-probe-via-chaoscenter-ui)
5. [Probe Type Details & YAML Examples](#5-probe-type-details--yaml-examples)
   - [HTTP Probe](#51-http-probe-httpprobe)
   - [CMD Probe](#52-cmd-probe-cmdprobe)
   - [K8s Probe](#53-k8s-probe-k8sprobe)
   - [Prometheus Probe](#54-prometheus-probe-promprobe)
6. [Probe Run Properties Reference](#6-probe-run-properties-reference)
7. [Probe Status & Results](#7-probe-status--results)
8. [Probe Chaining](#8-probe-chaining)
9. [Summary](#9-summary)

---

## 1. What are Resilience Probes?

**Resilience Probes** are pluggable checks that can be defined within the `ChaosEngine` for any Chaos Experiment. They validate the steady-state hypothesis — confirming that the system behaves as expected during and after chaos injection.

The fault pods execute these checks based on the mode they are defined in. Their success (or failure) is factored as a necessary condition in determining the final **verdict** of the chaos fault, alongside the standard built-in checks.

> 💡 **Why use probes?** Probes let you automate the process of gauging, analyzing, and reporting failures that occur during chaos experiments — giving you deeper insights into system resilience.

---

## 2. Types of Probes

LitmusChaos currently supports **four types** of Resilience Probes:

| Probe Type | Description |
|---|---|
| `httpProbe` | Queries a health/downstream URI and checks the HTTP response code |
| `cmdProbe` | Executes a shell command and matches the resulting output |
| `k8sProbe` | Performs CRUD operations against native & custom Kubernetes resources |
| `promProbe` | Executes PromQL queries and matches Prometheus metrics against conditions |

---

## 3. Probe Execution Modes

Probes can run at different phases of a chaos experiment:

| Mode | Description |
|---|---|
| `SOT` (Start of Test) | Pre-chaos check — executed before chaos is injected |
| `EOT` (End of Test) | Post-chaos check — executed after chaos completes |
| `Edge` | Executed both before **and** after chaos |
| `Continuous` | Runs continuously with a polling interval during chaos injection |
| `OnChaos` | Runs continuously strictly during the chaos duration |

---

## 4. Creating a Probe via ChaosCenter UI

### Step 1 — Go to the Resilience Probes Section

Navigate to the **Resilience Probes** page from the left navigation bar, then click the **New Probe** button.

![Step 1 - Resilience Probes page](https://docs.litmuschaos.io/assets/images/step-1-c5548c663b708fd525ca28572cdbc5bd.png)

---

### Step 2 — Select the Type of Probe

Choose the probe type you want to create: **HTTP**, **CMD**, **K8s**, or **Prometheus**.

![Step 2 - Select probe type](https://docs.litmuschaos.io/assets/images/step-2-26775d0dd4d435e7729db7e479908fe3.png)

---

### Step 3 — Enter the Probe Details

Fill in the basic details:
- **Name** *(required)*
- **Description** *(optional)*
- **Tags** *(optional)*

![Step 3 - Enter probe details](https://docs.litmuschaos.io/assets/images/step-3-84b6ce827731915916555cd11f3a0b86.png)

---

### Step 4 — Configure Probe Run Properties

Set the runtime behavior of the probe:

| Property | Description |
|---|---|
| `probeTimeout` | Time limit for the probe to execute and return data |
| `interval` | Period between subsequent retries |
| `retry` | Number of re-runs on failure before declaring the probe as failed |
| `probePollingInterval` | Sleep time between iterations (for Continuous/OnChaos modes) |
| `initialDelay` | Initial waiting time before the probe starts |
| `stopOnFailure` | Whether to stop the fault when the probe fails (`true`/`false`) |

![Step 4 - Configure probe properties](https://docs.litmuschaos.io/assets/images/step-4-0b884d209315aa5a11e3f37ebc7fc321.png)

---

### Step 5 — Configure Probe-Specific Details

Enter the configuration specific to the probe type (e.g., URL for HTTP probe, shell command for CMD probe). Click **Setup Probe** when done.

![Step 5 - Configure probe details](https://docs.litmuschaos.io/assets/images/step-5-5451e5b95a53a35573073fc98afcc907.png)

---

### Step 6 — Probe Created Successfully

The newly created probe will now appear in the probe list.

![Step 6 - Probe created and listed](https://docs.litmuschaos.io/assets/images/step-6-fef7ed6f77c9c73b046d1a950cd507ca.png)

---

## 5. Probe Type Details & YAML Examples

### 5.1 HTTP Probe (`httpProbe`)

The `httpProbe` checks the health or availability of a URL by sending an HTTP request and matching the response code. Supports both `GET` and `POST` methods.

**Best used in:** `Continuous` mode as a parallel liveness indicator.

```yaml
probe:
  - name: 'check-frontend-access-url'
    type: 'httpProbe'
    httpProbe/inputs:
      url: 'http://my-app-service/health'
      insecureSkipVerify: false
      responseTimeout: 500         # in milliseconds
      method:
        get:
          criteria: ==             # supports: ==, !=, oneOf
          responseCode: '200'
    mode: 'Continuous'
    runProperties:
      probeTimeout: 5s
      interval: 5s
      retry: 1
      probePollingInterval: 2s
```

> 💡 Set `insecureSkipVerify: true` to skip TLS certificate checks.

---

### 5.2 CMD Probe (`cmdProbe`)

The `cmdProbe` runs a shell command and validates the output. It supports two execution modes:
- **Inline** — command runs inside the fault pod (no extra image needed)
- **Source** — command runs in a new pod with a specified container image (useful when extra binaries are needed)

```yaml
probe:
  - name: 'check-database-integrity'
    type: 'cmdProbe'
    cmdProbe/inputs:
      command: 'curl -s http://db-service/status | jq .status'
      comparator:
        type: 'string'           # supports: string, int, float
        criteria: 'contains'    # string: contains, equal, notEqual, matches, notMatches
        value: 'healthy'
      source:                   # omit this block to run inline
        image: 'curlimages/curl:latest'
        hostNetwork: false
    mode: 'Edge'
    runProperties:
      probeTimeout: 5s
      interval: 5s
      retry: 1
      initialDelay: 5s
```

> 💡 Set `source.hostNetwork: true` to allow the probe pod access to the node's network namespace.

---

### 5.3 K8s Probe (`k8sProbe`)

The `k8sProbe` verifies the state of Kubernetes resources using the Kubernetes Dynamic Client. It supports CRUD operations: `create`, `delete`, `present`, `absent`.

```yaml
probe:
  - name: 'check-app-cluster-cr-status'
    type: 'k8sProbe'
    k8sProbe/inputs:
      group: 'apps'
      version: 'v1'
      resource: 'deployments'
      namespace: 'default'
      fieldSelector: 'metadata.name=my-app,status.phase=Running'
      labelSelector: 'app=my-app'
      operation: 'present'       # supports: present, absent, create, delete
    mode: 'EOT'
    runProperties:
      probeTimeout: 5s
      interval: 5s
      retry: 1
```

**Supported Operations:**

| Operation | Description |
|---|---|
| `create` | Creates a Kubernetes resource from the `data` field |
| `delete` | Deletes a resource matching the GVR + filters |
| `present` | Checks that a resource matching the GVR + filters **exists** |
| `absent` | Checks that a resource matching the GVR + filters **does not exist** |

---

### 5.4 Prometheus Probe (`promProbe`)

The `promProbe` runs a PromQL query against a Prometheus server and validates the result. This enables metrics-based SLOs defined declaratively.

```yaml
probe:
  - name: 'check-error-rate'
    type: 'promProbe'
    promProbe/inputs:
      endpoint: 'http://prometheus-service:9090'
      query: 'rate(http_requests_total{status="500"}[1m])'
      comparator:
        criteria: '<='            # supports: >=, <=, >, <, ==, !=
        value: '0.01'
    mode: 'Edge'
    runProperties:
      probeTimeout: 5s
      interval: 5s
      retry: 1
```

> 💡 For multi-line PromQL queries, use `queryPath` pointing to a file mounted via a ConfigMap instead of the `query` field. The two fields are **mutually exclusive**.

---

## 6. Probe Run Properties Reference

These properties are common across all probe types:

| Property | Type | Required | Description |
|---|---|---|---|
| `probeTimeout` | string | ✅ Yes | Max time for the probe to return a result |
| `interval` | string | ✅ Yes | Wait time between retries |
| `retry` | integer | ✅ Yes | Number of re-attempts before marking as failed |
| `probePollingInterval` | string | ❌ Optional | Sleep interval for Continuous/OnChaos modes |
| `initialDelay` | string | ❌ Optional | Waiting time before the first probe execution |
| `stopOnFailure` | boolean | ❌ Optional | Stop the fault if the probe fails (default: `false`) |

---

## 7. Probe Status & Results

After a chaos experiment runs, probe results are written to the `ChaosResult` custom resource. The key fields are:

- **`probeSuccessPercentage`** — ratio of successful probe checks vs total checks
- **Probe Status per phase** — pass/fail status for each mode (Pre Chaos, Post Chaos, Continuous)

Example `ChaosResult` snippet:

```yaml
Status:
  Experimentstatus:
    Phase: Completed
    Probe Success Percentage: 100
    Verdict: Pass

  Probe Status:
    - Name: check-frontend-access-url
      Status:
        Continuous: Passed 👍
      Type: HTTPProbe

    - Name: check-app-cluster-cr-status
      Status:
        Post Chaos: Passed 👍   # EOT
      Type: K8sProbe

    - Name: check-database-integrity
      Status:
        Pre Chaos:  Passed 👍
        Post Chaos: Passed 👍   # Edge
      Type: CmdProbe
```

> ⚠️ **Important:** The overall fault **verdict is the logical AND** of all probe results and built-in checks. If any probe fails, the fault is considered failed.

---

## 8. Probe Chaining

Probe chaining allows the output of one `cmdProbe` to be used as input in a subsequent probe. The result is referenced using the template syntax `{{ .<probeName>.ProbeArtifacts.Register }}`.

> ⚠️ Probe chaining is currently supported **only for `cmdProbes`**. The order of execution follows the order in which probes are defined in the ChaosEngine.

```yaml
probe:
  - name: 'probe1'
    type: 'cmdProbe'
    cmdProbe/inputs:
      command: 'kubectl get svc my-service -o jsonpath="{.spec.clusterIP}"'
      comparator:
        type: 'string'
        criteria: 'contains'
        value: '10.'
      source: 'inline'
    mode: 'SOT'
    runProperties:
      probeTimeout: 5s
      interval: 5s
      retry: 1

  - name: 'probe2'
    type: 'cmdProbe'
    cmdProbe/inputs:
      # Uses the output of probe1 as an argument
      command: 'curl -s http://{{ .probe1.ProbeArtifacts.Register }}/health'
      comparator:
        type: 'string'
        criteria: 'contains'
        value: 'ok'
      source: 'inline'
    mode: 'SOT'
    runProperties:
      probeTimeout: 5s
      interval: 5s
      retry: 1
```

---

## 9. Summary

| Probe Type | Use Case | Declarative? |
|---|---|---|
| `httpProbe` | Check service/URL availability | ✅ Fully declarative |
| `cmdProbe` | Run arbitrary shell commands or app-specific checks | ⚙️ Imperative (shell command) |
| `k8sProbe` | Verify Kubernetes resource state | ✅ Fully declarative |
| `promProbe` | Validate Prometheus metrics / SLOs | ✅ Fully declarative |

Probes are one of the most powerful features of LitmusChaos, enabling you to go beyond simple fault injection and truly validate the **resilience hypothesis** of your system in a reproducible, automated way.

---

## References

- 📹 Video: [Creating Probes in LitmusChaos | Chaos Engineering](https://youtu.be/CdL8kI7dGCo?si=0Uej1zDHJYo3RAOh)
- 📄 Concepts: [https://docs.litmuschaos.io/docs/concepts/probes](https://docs.litmuschaos.io/docs/concepts/probes)
- 📄 User Guide: [https://docs.litmuschaos.io/docs/user-guides/create-resilience-probe](https://docs.litmuschaos.io/docs/user-guides/create-resilience-probe)
- 🐙 GitHub: [https://github.com/litmuschaos/litmus](https://github.com/litmuschaos/litmus)