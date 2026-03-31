variable "rancher_access_key" {}
variable "rancher_secret_key" {}

variable "ssh_user" {
  default = "ubuntu"   # altere conforme seu usuário (ubuntu, debian, root, etc.)
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
