resource "kubernetes_config_map" "goip-init-script" {
  metadata {
    name      = "goip-init-script"
    namespace = kubernetes_namespace.sms.metadata[0].name
  }

  data = {
    "goipinit.sql" = file("${path.root}/goipinit.sql")
  }
}

resource "kubernetes_job" "goip-db-init" {
  metadata {
    name      = "goip-db-init"
    namespace = kubernetes_namespace.sms.metadata[0].name
  }

  spec {
    template {
      metadata {}

      spec {
        restart_policy = "Never"

        container {
          name  = "goip-db-init"
          image = "mariadb:11.3.2"

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.goip-sms-server-env.metadata[0].name
            }
          }

          command = [
            "/bin/sh",
            "-c",
            "mariadb --database=$MYSQL_MAIN_DB -h $MYSQL_MAIN_HOST -u $MYSQL_MAIN_LOGIN -p$MYSQL_MAIN_PASSWORD < /scripts/goipinit.sql",
          ]

          volume_mount {
            name       = "init-scripts"
            mount_path = "/scripts"
          }
        }

        volume {
          name = "init-scripts"
          config_map {
            name = kubernetes_config_map.goip-init-script.metadata.0.name
          }
        }
      }
    }
  }
}
