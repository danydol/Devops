# ─── Worker Node Group (created AFTER Calico is ready) ────────────────────────

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "nova" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.cluster_name}-node"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.vpc.private_subnets

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = "demo"
    ManagedBy   = "nova-agent"
  }

  tags = {
    Name = "${var.cluster_name}-node"
  }

  # Nodes join only after Calico CNI is fully ready
  depends_on = [
    kubernetes_manifest.calico_installation,
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}

# CoreDNS addon — added after node group exists so pods can be scheduled
resource "aws_eks_addon" "coredns" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "coredns"
  addon_version               = "v1.11.4-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.nova]
}
