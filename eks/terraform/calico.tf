# ─── Calico CNI via Tigera Operator ───────────────────────────────────────────
#
# EKS installs aws-node (VPC CNI) by default. We disable it by patching its
# nodeSelector to a label that no node will ever carry, then install Calico as
# the primary CNI before nodes join the cluster.

# 1. Disable aws-node DaemonSet (no node will match this selector)
resource "kubernetes_daemonset_v1" "disable_aws_node" {
  metadata {
    name      = "aws-node"
    namespace = "kube-system"
    annotations = {
      "calico/managed" = "true"
    }
  }

  spec {
    selector {
      match_labels = {
        k8s-app = "aws-node"
      }
    }

    strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          k8s-app = "aws-node"
        }
      }

      spec {
        # Only schedule on nodes with this label — deliberately unreachable
        node_selector = {
          "calico/cni-disabled" = "true"
        }

        container {
          name  = "aws-node"
          image = "public.ecr.aws/eks/amazon-k8s-cni:v1.18.1"

          env {
            name  = "DISABLE_TCP_EARLY_DEMUX"
            value = "true"
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}

# 2. Install Tigera Operator (Calico)
resource "helm_release" "calico" {
  name             = "calico"
  repository       = "https://docs.tigera.io/calico/charts"
  chart            = "tigera-operator"
  version          = var.calico_version
  namespace        = "tigera-operator"
  create_namespace = true

  wait    = true
  timeout = 300

  depends_on = [kubernetes_daemonset_v1.disable_aws_node]
}

# 3. Calico Installation CR — VXLAN overlay, Calico IPAM
resource "kubernetes_manifest" "calico_installation" {
  manifest = {
    apiVersion = "operator.tigera.io/v1"
    kind       = "Installation"
    metadata = {
      name = "default"
    }
    spec = {
      cni = {
        type = "Calico"
        ipam = {
          type = "Calico"
        }
      }
      calicoNetwork = {
        ipPools = [
          {
            name          = "default-ipv4-pool"
            cidr          = "192.168.0.0/16"
            encapsulation = "VXLAN"
            natOutgoing   = "Enabled"
            nodeSelector  = "all()"
          }
        ]
      }
    }
  }

  depends_on = [helm_release.calico]
}

# 4. Calico API Server CR
resource "kubernetes_manifest" "calico_apiserver" {
  manifest = {
    apiVersion = "operator.tigera.io/v1"
    kind       = "APIServer"
    metadata = {
      name = "default"
    }
    spec = {}
  }

  depends_on = [kubernetes_manifest.calico_installation]
}
