data "aws_availability_zones" "available" {
  state = "available"
}

# ─── VPC ───────────────────────────────────────────────────────────────────────

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# ─── EKS Cluster (no node groups yet — Calico must be installed first) ─────────

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # kube-proxy only — coredns needs nodes to schedule (added after node group joins)
  # NO vpc-cni (Calico replaces it)
  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
  }

  # Node group created AFTER Calico is installed (see nodes.tf)
  eks_managed_node_groups = {}

  # Allow the node role to access the cluster
  enable_cluster_creator_admin_permissions = true
}

# ─── IAM role for GitHub Actions (OIDC assume-role, no long-lived keys) ───────

# Import block — provider was pre-created via CLI; Terraform adopts it on first apply
import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::900720407869:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

import {
  to = aws_iam_role.github_actions
  id = "nova-eks-github-actions"
}

resource "aws_iam_role" "github_actions" {
  name               = "nova-eks-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
  description        = "Assumed by GitHub Actions via OIDC for ${var.github_repo}"
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
