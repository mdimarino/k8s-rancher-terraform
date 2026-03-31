terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 4.0"
    }
  }
}

provider "rancher2" {
  api_url    = "https://rancher.seu-dominio.com"
  access_key = var.rancher_access_key
  secret_key = var.rancher_secret_key
  insecure   = false
}
