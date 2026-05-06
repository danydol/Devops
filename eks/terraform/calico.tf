# ─── Calico CNI via Tigera Operator ───────────────────────────────────────────
#
# Nodes join AFTER Calico is installed (see nodes.tf depends_on).
# Because no nodes exist yet when Calico runs, they pick up Calico CNI
# on join — aws-node never gets a chance to configure them.

# 1. Install Tigera Operator (Calico)
resource "helm_release" "calico" {
  name             = "calico"
  repository       = "https://docs.tigera.io/calico/charts"
  chart            = "tigera-operator"
  version          = var.calico_version
  namespace        = "tigera-operator"
  create_namespace = true

  wait    = false

  depends_on = [module.eks]
}

# 2. Calico Installation CR — VXLAN overlay, Calico IPAM
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

# 3. Calico API Server CR
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
