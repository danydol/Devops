variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "nova-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "calico_version" {
  description = "Calico (Tigera operator) Helm chart version"
  type        = string
  default     = "v3.28.0"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the CI role (e.g. danydol/Devops)"
  type        = string
  default     = "danydol/Devops"
}
