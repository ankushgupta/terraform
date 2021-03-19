variable "vpc_id" {
  description = "String(required): The ID of the VPC in which to deploy"
  default = "vpc-c2ac2fa9"
}

variable "internal" {
  description = "Bool(optional, false): Is this an internal NLB or not"
  default     = false
}


variable "enable_deletion_protection" {
  description = "Bool(optional, false): Whether to enable deletion protection of this NLB or not"
  default     = false
}
