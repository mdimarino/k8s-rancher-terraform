# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform configuration to provision an RKE2 (Rancher Kubernetes Engine v2) cluster using the Rancher2 provider. It registers pre-existing VMs into Rancher over SSH, creating a 3-node cluster (1 control plane + 2 workers) with Cilium as the CNI.

## Commands

```bash
# Initialize providers
terraform init

# Preview changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars

# Destroy infrastructure
terraform destroy -var-file=terraform.tfvars
```

## Setup

Copy the example vars file and fill in your values before running any commands:

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` is gitignored — never commit it. It contains Rancher API credentials and SSH key paths.

## Architecture

**Flat root module** — no sub-modules. All resources are defined directly in the root:

- [provider.tf](provider.tf) — Rancher2 provider (~> 4.0) configured with `api_url`, `access_key`, and `secret_key`.
- [variables.tf](variables.tf) — Input variables: `rancher_access_key`, `rancher_secret_key`, `ssh_user` (default: `"ubuntu"`), `ssh_private_key_path`, `controlplane_ip`, `worker_ips` (list).
- [main.tf](main.tf) — Core resources:
  - `rancher2_cluster_v2.prod` — declares the cluster (Kubernetes v1.34.6+rke2r1, Cilium CNI, kube-proxy replacement enabled, ingress-nginx disabled, etcd retention 5 snapshots).
  - `null_resource.controlplane` — SSH provisioner that runs the RKE2 registration script on the control plane node (`--etcd --controlplane`).
  - `null_resource.workers` (count=2) — SSH provisioner that registers each worker node (`--worker`) after the control plane is ready.
- [outputs.tf](outputs.tf) — Exports `cluster_name`, `kubernetes_version`, and `registration_command`.

**Provisioning order:** cluster resource created first → control plane registered → workers registered (depends_on enforced).

## Prerequisites

- A running Rancher management server reachable at the URL set in [provider.tf](provider.tf).
- Pre-provisioned VMs accessible via SSH at the IPs provided in `terraform.tfvars`.
- Rancher API credentials (access key + secret key) from the Rancher UI.
