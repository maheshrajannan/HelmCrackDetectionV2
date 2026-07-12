# Platform Architecture — Helm Crack Detection V2

## Resource Inventory

| Layer | Resource | Name |
|---|---|---|
| GCP Infra (Terraform) | GCS Bucket (TF state) | `crack-detection-terraform` |
| GCP Infra (Terraform) | GKE Cluster | `crack-detection-cluster` (us-central1-a) |
| GCP Infra (Terraform) | Node Pool | `primary-node-pool` (e2-medium, 3-7 nodes) |
| GCP Infra (Deploy WF) | Global Static IP | `concrete-detection-ip` |
| GCP Infra (Deploy WF) | Cloud DNS Zone | `concrete-zone-1` |
| GCP Infra (Deploy WF) | DNS A Record | `maheshconcretegallery.online → IP` |
| GCP Infra (K8s) | GCE L7 Load Balancer | auto-created by GCE Ingress controller |
| GCP Infra (K8s) | Managed SSL Cert | `concrete-gallery-cert` |
| K8s / Helm | Ingress | `concrete-gallery-ingress` |
| K8s / Helm | NFS Server Deployment | `nfs-server-depl` |
| K8s / Helm | NFS Service (ClusterIP) | `nfs-server-svc-cip` |
| K8s / Helm | PersistentVolume | `concrete-images-pv-nfs` (10Gi, NFS) |
| K8s / Helm | PersistentVolumeClaim | `concrete-images-pvc-nfs` |
| K8s / Helm | Deployment | `concrete-image-gallery-depl` |
| K8s / Helm | Deployment | `image-upload-depl` |
| K8s / Helm | Deployment | `crack-detection-depl` |
| K8s / Helm | Service (NodePort) | `concrete-image-gallery-svc-lb` :8082 |
| K8s / Helm | Service (NodePort) | `image-upload-svc-lb` :8080 |
| K8s / Helm | Service (ClusterIP) | `crack-detection-svc` :8081 |

---

## Domain to Ingress Mapping

```mermaid
%%{init: {'themeVariables': {'fontSize': '48px'}, 'flowchart': {'nodeSpacing': 80, 'rankSpacing': 100, 'htmlLabels': true}}}%%
graph TD
    subgraph Hostinger ["🌍 Hostinger — Domain Registrar"]
        Domain["concretecrackgallery.online<br/>(purchased domain)"]
        HostingerNS["Hostinger Default Nameservers<br/>(overridden — delegated to GCP)"]
        CustomNS["Custom Nameservers set to GCP:<br/>ns-cloud-c1.googledomains.com<br/>ns-cloud-c2.googledomains.com<br/>ns-cloud-c3.googledomains.com<br/>ns-cloud-c4.googledomains.com"]
        Domain -->|"NS records replaced with"| CustomNS
    end

    subgraph GCP_DNS ["☁️ GCP Cloud DNS"]
        Zone["Managed Zone: concrete-zone-1<br/>DNS name: concretecrackgallery.online"]
        NSRecord["NS Record<br/>ns-cloud-c1..c4.googledomains.com"]
        SOA["SOA Record<br/>ns-cloud-c1.googledomains.com"]
        ARecord["A Record<br/>maheshconcretegallery.online<br/>→ 8.233.230.65"]
        ApexA["A Record (apex)<br/>concretecrackgallery.online<br/>→ 34.8.140.102"]

        Zone --> NSRecord
        Zone --> SOA
        Zone --> ARecord
        Zone --> ApexA
    end

    subgraph GCP_Network ["☁️ GCP Networking"]
        StaticIP["Global Static IP<br/>concrete-detection-ip<br/>8.233.230.65"]
        LB["GCE L7 Load Balancer<br/>(HTTPS :443 / HTTP :80)"]
        Cert["Managed Certificate<br/>concrete-gallery-cert<br/>maheshconcretegallery.online"]
        StaticIP -->|"bound to"| LB
        Cert -->|"TLS termination on"| LB
    end

    subgraph GKE ["☁️ GKE Cluster"]
        Ingress["Ingress: concrete-gallery-ingress<br/>annotations:<br/>• ingress.class: gce<br/>• global-static-ip-name: concrete-detection-ip<br/>• managed-certificates: concrete-gallery-cert<br/>host: maheshconcretegallery.online"]
        GallerySvc["concrete-image-gallery-svc-lb<br/>NodePort :8082"]
        UploadSvc["image-upload-svc-lb<br/>NodePort :8080"]
        Ingress -->|"/ → "| GallerySvc
        Ingress -->|"/upload /uploaded → "| UploadSvc
    end

    User(["👤 User<br/>browser"])

    %% DNS resolution chain
    User -->|"1. resolves maheshconcretegallery.online"| CustomNS
    CustomNS -->|"2. NS delegated to GCP Cloud DNS"| Zone
    Zone -->|"3. A record lookup"| ARecord
    ARecord -->|"4. returns 8.233.230.65"| User

    %% Traffic flow
    User -->|"5. HTTPS request to 8.233.230.65"| LB
    LB -->|"6. routes by host rule"| Ingress

    %% LB ← Ingress provisioning link
    Ingress -->|"triggers GCE LB provisioning"| LB

    %% Cert validation
    ARecord -->|"domain must resolve here\nfor cert provisioning"| Cert

    classDef hostinger fill:#FF6B35,color:#fff,stroke:#cc5528
    classDef gcpdns fill:#4285F4,color:#fff,stroke:#2a6dd9
    classDef gcpnet fill:#1a73e8,color:#fff,stroke:#1558b0
    classDef gke fill:#326CE5,color:#fff,stroke:#1a4fba
    classDef user fill:#FBBC04,color:#333,stroke:#e0a800

    class Domain,HostingerNS,CustomNS hostinger
    class Zone,NSRecord,SOA,ARecord,ApexA gcpdns
    class StaticIP,LB,Cert gcpnet
    class Ingress,GallerySvc,UploadSvc gke
    class User user
```

### How the delegation works

| Step | What happens |
|---|---|
| 1 | `concretecrackgallery.online` is purchased and registered at **Hostinger** |
| 2 | In Hostinger's DNS settings, the default nameservers are **replaced** with GCP's: `ns-cloud-c1..c4.googledomains.com` |
| 3 | All DNS queries for `*.concretecrackgallery.online` are now answered by **GCP Cloud DNS** (`concrete-zone-1`) |
| 4 | GCP Cloud DNS holds the A record: `maheshconcretegallery.online → 8.233.230.65` |
| 5 | `8.233.230.65` is the **reserved global static IP** (`concrete-detection-ip`) bound to the GCE L7 Load Balancer |
| 6 | The Load Balancer was provisioned by the **GCE Ingress controller** reading the `concrete-gallery-ingress` annotations |
| 7 | Traffic is routed by the ingress host rule to the appropriate **NodePort services** inside GKE |

> **Note:** The apex domain `concretecrackgallery.online` has a separate A record pointing to `34.8.140.102` — this is not managed by this stack and routes elsewhere.

---

## Sequence Diagram

```mermaid
%%{init: {'themeVariables': {'fontSize': '48px'}}}%%
sequenceDiagram
    actor Dev as Developer
    participant GHA as GitHub Actions
    participant TF as Terraform
    participant GCS as GCS Bucket<br/>(crack-detection-terraform)
    participant GCP as GCP Project<br/>(concrete-detection-1-491711)
    participant GKE as GKE Cluster<br/>(crack-detection-cluster)
    participant K8s as Kubernetes API
    participant DNS as Cloud DNS<br/>(concrete-zone-1)
    participant LB as GCE L7<br/>Load Balancer
    participant Cert as GCP Managed<br/>Certificate

    rect rgb(220, 235, 255)
        Note over Dev,GCS: Phase 1 — Cluster Provisioning (Mahesh Kubernetes Cluster Provisioning workflow)
        Dev->>GHA: Trigger: provider=gcp, action=apply
        GHA->>GCS: terraform init (remote state backend)
        GHA->>GCP: Auth via MAHESH_GCP_CD_2_SA_KEY
        GHA->>TF: terraform plan → apply
        TF->>GCP: Create GKE Cluster (crack-detection-cluster, us-central1-a)
        TF->>GKE: Create Node Pool (primary-node-pool, e2-medium, 3–7 nodes)
        TF->>GCS: Save terraform.tfstate
        GKE-->>GHA: Cluster Ready
    end

    rect rgb(220, 255, 220)
        Note over Dev,Cert: Phase 2 — Application Deploy (Mahesh-GKE-SSL-deploy workflow)
        Dev->>GHA: Trigger: manual workflow_dispatch
        GHA->>GCP: Auth + gcloud get-credentials
        GHA->>GKE: kubectl context configured

        GHA->>GCP: Create Global Static IP (concrete-detection-ip)
        GCP-->>GHA: IP reserved (e.g. 8.233.230.65)

        Note over GHA,K8s: Helm Deploy — NFS Server
        GHA->>K8s: helm install nfs-server
        K8s->>K8s: Create nfs-server-depl (emptyDir volume)
        K8s->>K8s: Create nfs-server-svc-cip (ClusterIP :2049/:20048/:111)

        Note over GHA,K8s: populateCIP.py — inject NFS ClusterIP into values
        GHA->>K8s: kubectl get svc nfs-server-svc-cip
        K8s-->>GHA: ClusterIP (e.g. 10.96.0.13)
        GHA->>GHA: Write NFS IP into masterChart values

        Note over GHA,K8s: Helm Deploy — Master Chart
        GHA->>K8s: helm install master-chart
        K8s->>K8s: Create PV (concrete-images-pv-nfs, 10Gi NFS)
        K8s->>K8s: Create PVC (concrete-images-pvc-nfs)
        K8s->>K8s: Create concrete-image-gallery-depl + svc (NodePort :8082)
        K8s->>K8s: Create image-upload-depl + svc (NodePort :8080)
        K8s->>K8s: Create crack-detection-depl + svc (ClusterIP :8081)
        K8s->>K8s: Create ManagedCertificate (concrete-gallery-cert)
        K8s->>K8s: Create Ingress (concrete-gallery-ingress)<br/>annotations: gce class, static IP, managed cert

        Note over K8s,LB: GCE Ingress Controller kicks in
        K8s->>LB: Provision GCE L7 Load Balancer
        LB->>GCP: Bind to static IP (concrete-detection-ip)
        LB->>K8s: Register NodePort backends (gallery :8082, upload :8080)
        LB-->>K8s: Ingress IP assigned (8.233.230.65)
    end

    rect rgb(255, 245, 200)
        Note over GHA,Cert: Phase 3 — DNS + SSL
        GHA->>DNS: Check/Create managed zone (concrete-zone-1)
        GHA->>K8s: Poll for ingress IP
        K8s-->>GHA: 8.233.230.65
        GHA->>DNS: Upsert A record<br/>maheshconcretegallery.online → 8.233.230.65

        DNS-->>Cert: Domain resolves to LB IP
        K8s->>Cert: ManagedCertificate provisioning triggered
        Cert->>LB: HTTP-01 domain validation via port 80
        Cert-->>K8s: Certificate Status: Active
        LB->>LB: Enable HTTPS (port 443) with provisioned cert
    end

    rect rgb(255, 220, 220)
        Note over Dev,LB: Phase 4 — Traffic Flow (steady state)
        Dev->>LB: HTTPS → maheshconcretegallery.online
        LB->>K8s: Route / → concrete-image-gallery-svc-lb :8082
        LB->>K8s: Route /upload → image-upload-svc-lb :8080
        K8s->>K8s: image-upload-depl calls crack-detection-svc :8081 (internal)
    end
```

---

## System Diagram

```mermaid
%%{init: {'themeVariables': {'fontSize': '48px'}}}%%
graph TB
    User(["👤 User\nBrowser"])

    subgraph GCP ["GCP Project — concrete-detection-1-491711"]

        subgraph Networking ["GCP Networking"]
            StaticIP["🌐 Global Static IP\nconcrete-detection-ip\n8.233.230.65"]
            DNS["🗺 Cloud DNS\nconcrete-zone-1\nmaheshconcretegallery.online"]
            Cert["🔒 Managed Certificate\nconcrete-gallery-cert\n(SSL/TLS)"]
            LB["⚖️ GCE L7 Load Balancer\n(auto-provisioned by GCE Ingress)"]
        end

        subgraph GKE ["GKE Cluster — crack-detection-cluster (us-central1-a)"]

            subgraph NodePool ["Node Pool — primary-node-pool (e2-medium, 3–7 nodes)"]

                Ingress["📡 Ingress\nconcrete-gallery-ingress\nclass: gce"]

                subgraph AppPods ["Application Pods"]
                    GalleryDep["🖼 concrete-image-gallery-depl\n:8082"]
                    UploadDep["📤 image-upload-depl\n:8080"]
                    CrackDep["🔍 crack-detection-depl\n:8081"]
                end

                subgraph Services ["Services"]
                    GallerySvc["concrete-image-gallery-svc-lb\nNodePort :8082"]
                    UploadSvc["image-upload-svc-lb\nNodePort :8080"]
                    CrackSvc["crack-detection-svc\nClusterIP :8081"]
                end

                subgraph Storage ["Storage"]
                    NFSDep["🗄 nfs-server-depl\n(emptyDir)"]
                    NFSSvc["nfs-server-svc-cip\nClusterIP :2049"]
                    PV["💾 PersistentVolume\nconcrete-images-pv-nfs\n10Gi NFS"]
                    PVC["📋 PersistentVolumeClaim\nconcrete-images-pvc-nfs"]
                end

            end
        end

        GCS["🪣 GCS Bucket\ncrack-detection-terraform\n(Terraform state)"]
    end

    subgraph CICD ["CI/CD — GitHub Actions"]
        WF1["Mahesh Kubernetes\nCluster Provisioning\n(Terraform)"]
        WF2["Mahesh-GKE-SSL-deploy\n(Helm)"]
        DockerHub["🐳 DockerHub\nimage-upload-logic\ncrack-detection-logic\nconcrete-image-gallery-logic"]
    end

    %% User traffic flow
    User -->|"HTTPS :443\nmaheshconcretegallery.online"| DNS
    DNS -->|"A record → 8.233.230.65"| LB
    Cert -->|"TLS termination"| LB
    StaticIP -->|"bound to"| LB
    LB -->|"/ :8082"| GallerySvc
    LB -->|"/upload /uploaded :8080"| UploadSvc

    %% Service to pod
    GallerySvc --> GalleryDep
    UploadSvc --> UploadDep
    CrackSvc --> CrackDep

    %% Internal service call
    UploadDep -->|"internal :8081"| CrackSvc

    %% Ingress to LB
    Ingress -->|"triggers provisioning"| LB

    %% Storage wiring
    NFSSvc --> NFSDep
    PV -->|"NFS mount"| NFSSvc
    PVC -->|"bound to"| PV
    GalleryDep -->|"mounts"| PVC
    UploadDep -->|"mounts"| PVC
    CrackDep -->|"mounts"| PVC

    %% CI/CD provisioning
    WF1 -->|"terraform apply"| GKE
    WF1 -->|"state"| GCS
    WF2 -->|"helm install"| Ingress
    WF2 -->|"creates"| StaticIP
    WF2 -->|"upserts A record"| DNS
    WF2 -->|"pulls images"| DockerHub
    DockerHub -->|"image pull"| AppPods

    %% Cert provisioning
    DNS -->|"domain resolves"| Cert

    %% Styling
    classDef gcp fill:#4285F4,color:#fff,stroke:#2a6dd9
    classDef k8s fill:#326CE5,color:#fff,stroke:#1a4fba
    classDef storage fill:#34A853,color:#fff,stroke:#1e7a35
    classDef cicd fill:#EA4335,color:#fff,stroke:#c0392b
    classDef user fill:#FBBC04,color:#333,stroke:#e0a800

    class StaticIP,DNS,Cert,LB,GCS gcp
    class Ingress,GallerySvc,UploadSvc,CrackSvc,GalleryDep,UploadDep,CrackDep k8s
    class NFSDep,NFSSvc,PV,PVC storage
    class WF1,WF2,DockerHub cicd
    class User user
```

---

## Notes

- `crack-detection-svc` is internal-only (ClusterIP, no ingress path) — called service-to-service from the upload pod
- The NFS server uses `emptyDir` (not a persistent disk), so **uploaded images are lost if the NFS pod restarts**
- The `concretecrackgallery.online` apex domain A record points to a different IP (`34.8.140.102`) which is not managed by this stack
- GCE Ingress requires `NodePort` services — `ClusterIP` services will cause the load balancer backend sync to fail
