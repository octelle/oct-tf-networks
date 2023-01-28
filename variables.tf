variable "accounts" {
  description = "list of account ids"
  type        = any
  default     = { "prod" = "147132488621", "deployment" = "573573194887" }
}

variable "region" {
  description = "Region for creating AWS resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Name of environment"
  type        = string
  default     = "prod"
}
