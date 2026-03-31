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

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply -var-file=terraform.tfvars
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

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | Created cluster name |
| `kubernetes_version` | Kubernetes version running |
| `registration_command` | Base node registration command for manual use |
