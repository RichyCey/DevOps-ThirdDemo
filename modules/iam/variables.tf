# modules/iam/variables.tf

variable "eks_url" {
  description = "URL for the EKS OIDC provider"
  type        = string
}

variable "role_name" {
  description = "Name for the IAM role"
  type        = string
}

variable "policy_name" {
  description = "Name for the IAM policy"
  type        = string
}

variable "policy_json" {
  description = "JSON policy document for IAM policy"
  type        = string
}
