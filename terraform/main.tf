terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

provider "kubernetes" {
  config_path = "/home/ubuntu/.kube/config"
}

resource "kubernetes_deployment" "blue" {
  metadata {
    name = "myapp-blue"
    labels = {
      app   = "myapp"
      color = "blue"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app   = "myapp"
        color = "blue"
      }
    }

    template {
      metadata {
        labels = {
          app   = "myapp"
          color = "blue"
        }
      }

      spec {
        automount_service_account_token = false
        enable_service_links            = false

        container {
          name              = "myapp"
          image             = "myapp:v1"
          image_pull_policy = "Never"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  wait_for_rollout = true
}

resource "kubernetes_deployment" "green" {
  metadata {
    name = "myapp-green"
    labels = {
      app   = "myapp"
      color = "green"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app   = "myapp"
        color = "green"
      }
    }

    template {
      metadata {
        labels = {
          app   = "myapp"
          color = "green"
        }
      }

      spec {
        automount_service_account_token = false
        enable_service_links            = false

        container {
          name              = "myapp"
          image             = "myapp:v2"
          image_pull_policy = "Never"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  wait_for_rollout = true
}

resource "kubernetes_service" "myapp" {
  metadata {
    name = "myapp-service"
  }

  spec {
    type = "NodePort"

    selector = {
      app   = "myapp"
      color = "green"
    }

    port {
      port        = 80
      target_port = 80
      node_port   = 30080
    }
  }

  wait_for_load_balancer = false

  depends_on = [
    kubernetes_deployment.blue,
    kubernetes_deployment.green
  ]
}
