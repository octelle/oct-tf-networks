variable "name" {
  type        = string
  description = "VPC Name"
}

variable "short_name" {
  type        = string
  description = "Short Name"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "azs" {
  type        = list(string)
  description = "List of AZs"
}

#region target accounts
variable "share_private_subnets_with" {
  type = string
}

variable "share_deployment_subnets_with" {
  type = string
}
#endregion

#region Subnets
variable "private_subnets" {
  type        = map(any)
  description = "Map of subnet name -> subnet cidr"
}

variable "public_subnets" {
  type        = map(any)
  description = "Map of subnet name -> subnet cidr"
}

variable "deployment_subnets" {
  type        = map(any)
  description = "Map of subnet name -> subnet cidr"
}

variable "transitgw_subnets" {
  type        = map(any)
  description = "Map of subnet name -> subnet cidr"
}
#endregion

#region tags
variable "default_tags" {
  type = map(any)
}

variable "public_subnet_tags" {
  type = map(any)
}

variable "private_subnet_tags" {
  type = map(any)
}

variable "intra_subnet_tags" {
  type = map(any)
}
#endregion

#region nat gateway
variable "enable_nat_gateway" {
  type = string
}

variable "enable_vpn_gateway" {
  type = string
}

variable "one_nat_gateway_per_az" {
  type = string
}

variable "single_nat_gateway" {
  type = string
}
#endregion

#region flow_log vars
variable "enable_flow_log" {
  type = string
}

variable "flow_log_destination_type" {
  type = string
}

variable "flow_log_destination_arn" {
  type = string
}

variable "create_flow_log_cloudwatch_log_group" {
  type = string
}

variable "create_flow_log_cloudwatch_iam_role" {
  type = string
}

variable "flow_log_max_aggregation_interval" {
  type = string
}

variable "flow_log_cloudwatch_log_group_retention_in_days" {
  type = string
}
#endregion
