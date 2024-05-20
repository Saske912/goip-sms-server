resource "kubernetes_namespace" "sms" {
  metadata {
    name = "sms"
  }
}

data "vault_kv_secret_v2" "goip" {
  mount = "api_providers"
  name  = "goip"
}

resource "kubernetes_secret_v1" "goip-sms-server-env" {
  metadata {
    name      = "goip-sms-server-env"
    namespace = kubernetes_namespace.sms.metadata[0].name
  }

  data = {
    MYTIMEZONE          = "Europe/Moscow"
    GOIP_WEB_LOGIN      = random_string.username.result
    GOIP_WEB_PASSWORD   = random_password.password.result
    MYSQL_MAIN_HOST     = data.vault_kv_secret_v2.mariadb.data["implicit_host"]
    MYSQL_MAIN_PORT     = "3306"
    MYSQL_MAIN_DB       = mysql_database.goipsms.name
    MYSQL_MAIN_LOGIN    = random_string.username.result
    MYSQL_MAIN_PASSWORD = random_password.password.result
  }
}

resource "kubernetes_deployment" "goip-sms-server" {
  depends_on = [kubernetes_job.goip-db-init]
  metadata {
    name      = "goip-sms-server"
    namespace = kubernetes_namespace.sms.metadata[0].name
    labels = {
      app = "goip-sms-server"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "goip-sms-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "goip-sms-server"
        }
      }

      spec {
        container {
          name  = "goip-sms-server"
          image = "bzmn/goip-sms-server"

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.goip-sms-server-env.metadata[0].name
            }
          }
          port {
            container_port = 44444
            protocol       = "UDP"
          }

          port {
            container_port = 80
            protocol       = "TCP"
          }
        }
      }
    }
  }
}
