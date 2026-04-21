output "cluster_name" {
  value = module.cluster.cluster_name
}

output "kubernetes_version" {
  value = module.cluster.kubernetes_version
}

output "registration_command" {
  value       = module.cluster.registration_command
  description = "Comando base de registro (caso precise rodar manualmente)"
  sensitive   = true
}

output "kubeconfig" {
  value       = module.cluster.kubeconfig
  description = "Contents of /etc/rancher/rke2/rke2.yaml from the control plane"
  sensitive   = true
}
