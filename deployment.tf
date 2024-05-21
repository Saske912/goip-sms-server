resource "kubernetes_namespace" "sms" {
  metadata {
    name = "sms"
  }
}

# Define the Docker image for goip-sms-server
resource "kubernetes_deployment" "goip-sms-server" {
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
          image = "doanbaanh/goip-sms-server:latest"

          port {
            container_port = 80
            protocol       = "TCP"
          }

          port {
            container_port = 44444
            protocol       = "UDP"
          }

          volume_mount {
            name       = "goip-sms-server-data"
            mount_path = "/var/lib/mysql"
          }
        }
        volume {
          name = "goip-sms-server-data"
          persistent_volume_claim {
            claim_name = "goip-sms-server-data"
          }
        }
      }
    }
  }
}

# Define the persistent volume claim for goip-sms-server-data
resource "kubernetes_persistent_volume_claim" "goip-sms-server-data" {
  metadata {
    name      = "goip-sms-server-data"
    namespace = kubernetes_namespace.sms.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi" # Adjust the storage size as needed
      }
    }
  }
}
