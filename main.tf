resource "rancher2_setting" "server_url" {
  name  = "server-url"
  value = var.rancher_url
}

module "cluster" {
  source = "./modules/rke2-cluster"

  ssh_user             = var.ssh_user
  ssh_private_key_path = var.ssh_private_key_path
  controlplane_ip      = var.controlplane_ip
  worker_ips           = var.worker_ips
  lb_ip_pool           = var.lb_ip_pool
  cluster_name         = var.cluster_name
  kubernetes_version   = var.kubernetes_version
  cluster_cidr         = var.cluster_cidr
  service_cidr         = var.service_cidr
}
