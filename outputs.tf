output "cluster_name" {
  value = rancher2_cluster_v2.prod.name
}

output "kubernetes_version" {
  value = rancher2_cluster_v2.prod.kubernetes_version
}

output "registration_command" {
  value       = rancher2_cluster_v2.prod.cluster_registration_token[0].insecure_node_command
  description = "Comando base de registro (caso precise rodar manualmente)"
  sensitive   = true
}
