resource "rancher2_cluster_v2" "prod" {
  name                  = "meu-cluster-prod"
  kubernetes_version    = "v1.34.6+rke2r1"   # Versão RKE2 baseada em Kubernetes 1.34
  enable_network_policy = false

  rke_config {
    # Configuração global do RKE2 + Cilium
    machine_global_config = jsonencode({
      cni                 = "cilium"
      "disable-kube-proxy" = true          # Recomendado quando usa Cilium com Kube-Proxy Replacement
      "disable"           = ["rke2-ingress-nginx"]
    })

    upgrade_strategy {
      control_plane_concurrency = "1"
      worker_concurrency        = "1"
    }

    etcd {
      snapshot_retention = 5
    }
  }

  labels = {
    environment = "production"
  }
}

# =============================================
# 1. Control Plane (1 nó)
# =============================================
resource "null_resource" "controlplane" {
  depends_on = [rancher2_cluster_v2.prod]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = var.controlplane_ip
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fL ${rancher2_cluster_v2.prod.cluster_registration_token[0].insecure_node_command} | sh -s - --etcd --controlplane"
    ]
  }
}

# =============================================
# 2. Workers (2 nós) + label "worker"
# =============================================
resource "null_resource" "workers" {
  count      = 2
  depends_on = [null_resource.controlplane]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = var.worker_ips[count.index]
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fL ${rancher2_cluster_v2.prod.cluster_registration_token[0].insecure_node_command} | sh -s - --worker",
      # Aplica label nos workers após o registro
      "kubectl label node $(hostname) worker=true --overwrite || true"
    ]
  }
}
