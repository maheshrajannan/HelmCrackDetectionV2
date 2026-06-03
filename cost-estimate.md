# Cost Estimate — 3-Day Run (72 hours)

Based on GCP pricing for `crack-detection-cluster` in `us-central1-a`.

## Breakdown

| Resource | Rate | Qty | 72 hrs | Cost |
|---|---|---|---|---|
| **e2-medium nodes** | $0.055/hr | 3 nodes (min) | 72 hrs | **$11.88** |
| **GKE cluster management fee** | $0.10/hr | 1 cluster | 72 hrs | **$7.20** ¹ |
| **GCE L7 Load Balancer** (forwarding rules) | ~$0.025/hr | 1 LB | 72 hrs | **$1.80** |
| **Global Static IP** (in use) | $0.004/hr | 1 IP | 72 hrs | **$0.29** |
| **Cloud DNS** (managed zone) | $0.20/month | 1 zone | 3 days | **$0.02** |
| **GCS bucket** (Terraform state) | ~$0.02/GB/month | minimal | 3 days | **~$0.00** |
| **Persistent disk** (20GB × 3 nodes) | $0.04/GB/month | 60 GB | 3 days | **$0.08** |
| | | | **Total** | **~$21.27** |

## Notes

¹ **GKE waives the $0.10/hr cluster management fee for the first zonal cluster per billing account per month.**
Since `crack-detection-cluster` is a single-zone cluster (`us-central1-a`), this fee is likely **$0** if it's your only active cluster — dropping the total to **~$14**.

- Nodes autoscale up to 7 — each additional node adds ~$3.96 per 72 hrs
- No egress costs assumed (no significant outbound traffic)
- GCP sustained use discounts don't apply to a 3-day run (require 25%+ of the month)
- If still on a free trial, all costs are covered by the $300 GCP credit

## Summary

| Scenario | Estimated Cost |
|---|---|
| 3 nodes, cluster fee waived | **~$14** |
| 3 nodes, cluster fee charged | **~$21** |
| 7 nodes (max autoscale), fee waived | **~$30** |
| 7 nodes (max autoscale), fee charged | **~$37** |
