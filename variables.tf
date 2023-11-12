variable "ecr_name" {
  description = "The list of ecr names to create"
  type        = list(string)
  default     = ["softserve-demo"]
}
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {"Environment" = "Dev"}
}
variable "image_mutability" {
  description = "Provide image mutability"
  type        = string
  default     = "IMMUTABLE"
}

variable "encrypt_type" {
  description = "Provide type of encryption here"
  type        = string
  default     = "KMS"
}
