variable "ssh_user" {
  default = "debian" # altere conforme seu usuário (ubuntu, debian, root, etc.)
}

variable "ssh_private_key_path" {
  type        = string
  description = "Caminho para a chave SSH privada"
}

variable "controlplane_ip" {
  type = string
}

variable "worker_ips" {
  type = list(string)
}

variable "lb_ip_pool" {
  type        = list(string)
  description = "Lista de CIDRs para o CiliumLoadBalancerIPPool"
}

variable "cluster_name" {
  type        = string
  description = "Nome do cluster RKE2 no Rancher"
}

variable "kubernetes_version" {
  type        = string
  description = "Versão do Kubernetes/RKE2"
  default     = "v1.34.6+rke2r1"
}

variable "cluster_cidr" {
  type        = string
  description = "CIDR para os pods do cluster"
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = "CIDR para os services do cluster"
  default     = "10.96.0.0/18"
}
