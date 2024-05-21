resource "kubernetes_service" "goip-sms-server-udp" {
  metadata {
    name      = "sms"
    namespace = kubernetes_namespace.sms.metadata[0].name
  }
  spec {
    selector = {
      app = "goip-sms-server"
    }
    type = "LoadBalancer"
    port {
      port        = 44444
      target_port = 44444
      protocol    = "UDP"
      name        = "udp"
    }
    port {
      port        = 8082
      target_port = 80
      name        = "http"
      protocol    = "TCP"
    }
  }
}
