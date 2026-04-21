resource "rancher2_cluster_v2" "prod" {
  name                  = var.cluster_name
  kubernetes_version    = var.kubernetes_version
  enable_network_policy = false

  rke_config {
    # Configuração global do RKE2 + Cilium
    machine_global_config = <<-EOF
      cni: "cilium"
      cluster-cidr: "${var.cluster_cidr}"
      service-cidr: "${var.service_cidr}"
      disable-kube-proxy: true
      disable:
        - rke2-ingress-nginx
    EOF

    chart_values = <<-EOF
      rke2-cilium:
        k8sServiceHost: ${var.controlplane_ip}
        k8sServicePort: "6443"
        hubble:
          enabled: true
          relay:
            enabled: true
          ui:
            enabled: true
        kubeProxyReplacement: true
        l2announcements:
          enabled: true
        operator:
          replicas: 1
    EOF

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
      "${rancher2_cluster_v2.prod.cluster_registration_token[0].insecure_node_command} --etcd --controlplane --worker"
    ]
  }
}

# =============================================
# LB-IPAM: pool de IPs + política L2 do Cilium
# =============================================
resource "null_resource" "cilium_lb" {
  depends_on = [null_resource.workers]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = var.controlplane_ip
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo tee /var/lib/rancher/rke2/server/manifests/cilium-lb-pool.yaml > /dev/null <<'EOF'\napiVersion: cilium.io/v2\nkind: CiliumLoadBalancerIPPool\nmetadata:\n  name: homelab-pool\nspec:\n  blocks:\n${join("\n", [for cidr in var.lb_ip_pool : "  - cidr: ${cidr}"])}\nEOF",
      "sudo tee /var/lib/rancher/rke2/server/manifests/cilium-l2-policy.yaml > /dev/null <<'EOF'\napiVersion: cilium.io/v2alpha1\nkind: CiliumL2AnnouncementPolicy\nmetadata:\n  name: default\nspec:\n  loadBalancerIPs: true\n  serviceSelector: {}\n  nodeSelector: {}\nEOF"
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
      "${rancher2_cluster_v2.prod.cluster_registration_token[0].insecure_node_command} --worker",
      # Aplica label nos workers após o registro
      "kubectl label node $(hostname) worker=true --overwrite || true"
    ]
  }
}

data "external" "kubeconfig" {
  depends_on = [null_resource.controlplane]

  program = [
    "bash", "-c",
    "ssh -o StrictHostKeyChecking=no -o BatchMode=yes -i '${var.ssh_private_key_path}' '${var.ssh_user}@${var.controlplane_ip}' 'sudo cat /etc/rancher/rke2/rke2.yaml' | python3 -c \"import sys,json; print(json.dumps({'content': sys.stdin.read()}))\""
  ]
}
