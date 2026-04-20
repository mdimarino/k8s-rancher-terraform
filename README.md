# k8s-rancher-terraform

Terraform configuration to provision an RKE2 Kubernetes cluster via Rancher2. Registers pre-existing VMs into Rancher over SSH, creating a 3-node cluster with Cilium CNI.

## Cluster topology

| Role | Count |
|------|-------|
| Control plane + etcd | 1 |
| Worker | 2 |

**Kubernetes version:** v1.34.6+rke2r1  
**CNI:** Cilium (kube-proxy replacement enabled)  
**Ingress:** rke2-ingress-nginx disabled

## Prerequisites

- Rancher management server running and accessible
- 3 VMs reachable via SSH with the same user/key
- Rancher API credentials (access key + secret key)

## Project layout

This repo is organised as a reusable child module plus a thin root that calls it, so multiple clusters can share the same code but keep separate state.

```
.
├── modules/rke2-cluster/   # reusable cluster module
├── main.tf                 # root: rancher2_setting + module call
├── provider.tf             # rancher2 provider config
├── variables.tf            # root inputs (forwarded to the module)
├── outputs.tf              # forwards module outputs
└── terraform-k8s-<N>.tfvars  # one file per cluster
```

State is isolated per cluster via Terraform workspaces — each workspace gets its own state file under `terraform.tfstate.d/<workspace>/`, so an apply on one cluster never touches another.

## Usage

Create a `.tfvars` file per cluster (one already exists for each of `k8s-2`…`k8s-5`). Use [terraform.tfvars.example](terraform.tfvars.example) as a template for new clusters.

One-time init:

```bash
terraform init
```

Provision each cluster in its own workspace:

```bash
# First time per cluster — creates the workspace:
terraform workspace new k8s-2
terraform apply -var-file=terraform-k8s-2.tfvars

terraform workspace new k8s-3
terraform apply -var-file=terraform-k8s-3.tfvars

terraform workspace new k8s-4
terraform apply -var-file=terraform-k8s-4.tfvars

terraform workspace new k8s-5
terraform apply -var-file=terraform-k8s-5.tfvars
```

Switching between existing clusters:

```bash
terraform workspace select k8s-3
terraform plan -var-file=terraform-k8s-3.tfvars
```

Running applies in parallel (each shell sets its own `TF_WORKSPACE`, avoiding the shared `.terraform/environment` file):

```bash
TF_WORKSPACE=k8s-2 terraform apply -var-file=terraform-k8s-2.tfvars &
TF_WORKSPACE=k8s-3 terraform apply -var-file=terraform-k8s-3.tfvars &
wait
```

Destroying one cluster only touches its own workspace state:

```bash
terraform workspace select k8s-3
terraform destroy -var-file=terraform-k8s-3.tfvars
```

## Variables

| Variable | Description |
|----------|-------------|
| `rancher_access_key` | Rancher API access key |
| `rancher_secret_key` | Rancher API secret key |
| `ssh_user` | SSH user on the nodes (default: `ubuntu`) |
| `ssh_private_key_path` | Path to SSH private key |
| `controlplane_ip` | IP of the control plane node |
| `worker_ips` | List of worker node IPs |

## Post-provisioning steps

After `terraform apply` completes, apply the control plane taint manually. The taint cannot be set during node registration and must be applied once the cluster is ready.

```bash
kubectl apply -f manifests/controlplane-taint.yaml
kubectl -n kube-system wait --for=condition=Complete job/apply-controlplane-taint --timeout=60s
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

The Job runs on a worker node, applies `node-role.kubernetes.io/control-plane=:NoSchedule` to all control plane nodes, and self-deletes after 2 minutes.

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | Created cluster name |
| `kubernetes_version` | Kubernetes version running |
| `registration_command` | Base node registration command for manual use |
