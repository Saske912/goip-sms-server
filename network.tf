resource "kubernetes_service" "goip-sms-server" {
  metadata {
    name      = "goip-sms-server"
    namespace = kubernetes_namespace.sms.metadata[0].name
  }
  spec {
    selector = {
      app = "goip-sms-server"
    }
    type = "ClusterIP"
    port {
      port        = 80
      target_port = 80
      name        = "http"
    }
  }
}

resource "kubernetes_service" "goip-sms-server-udp" {
  metadata {
    name      = "goip-sms-server-udp"
    namespace = kubernetes_namespace.sms.metadata[0].name
  }
  spec {
    selector = {
      udp = "goip-sms-server"
    }
    type = "LoadBalancer"
    port {
      port        = 44444
      target_port = 44444
      protocol    = "UDP"
      name        = "udp"
    }
  }
}

data "vault_kv_secret_v2" "issuer" {
  mount = "kubernetes"
  name  = "cluster"
}

resource "kubernetes_ingress_v1" "goip-sms-server" {
  metadata {
    name      = "goip-sms-server-ingress"
    namespace = kubernetes_namespace.sms.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "cert-manager.io/cluster-issuer"                 = data.vault_kv_secret_v2.issuer.data["cluster_issuer"]
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/limit-rpm"          = "60"
    }
  }

  spec {
    tls {
      hosts       = [var.goipsms.host]
      secret_name = "${var.goipsms.host}-tls"
    }

    rule {
      host = var.goipsms.host
      http {
        path {
          backend {
            service {
              name = kubernetes_service.goip-sms-server.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
