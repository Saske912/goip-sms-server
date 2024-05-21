terraform {
  required_providers {
    mysql = {
      source  = "petoju/mysql"
      version = "3.0.60"
    }
  }
}

provider "vault" {}

data "vault_kv_secret_v2" "k8s" {
  mount = "kubernetes"
  name  = "data"
}
locals {
  k8s = data.vault_kv_secret_v2.k8s.data
}
provider "kubernetes" {
  host                   = local.k8s["host"]
  client_certificate     = local.k8s["cert"]
  client_key             = local.k8s["key"]
  cluster_ca_certificate = local.k8s["ca"]
}

data "vault_kv_secret_v2" "mariadb" {
  mount = "storage"
  name  = "mariadb"
}

provider "mysql" {
  endpoint = "${data.vault_kv_secret_v2.mariadb.data["host"]}:3306"
  username = "root"
  password = data.vault_kv_secret_v2.mariadb.data["rootPassword"]
}
