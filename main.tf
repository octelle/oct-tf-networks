######################
# Create VPCs
#   VPCs are defined in locals.tf
#   VPCs selected by provided var.environment and var.region
#   VPCs are created in networking account and use VPC sharing for access in other workload accounts (see sharing.tf)
######################
provider "aws" {
  region = var.region
  default_tags {
    tags = local.default_tags
  }
  profile = "rjs-mgmt"
}

provider "aws" {
  alias  = "workload"
  region = var.region
  assume_role {
    role_arn     = "arn:aws:iam::${var.accounts[var.environment]}:role/TerraformCloudRole"
    session_name = "TERRAFORM_CLOUD"
  }
  profile = "rjs-mgmt"
}

provider "aws" {
  alias  = "deployment"
  region = var.region
  assume_role {
    role_arn     = "arn:aws:iam::${var.accounts.deployment}:role/TerraformCloudRole"
    session_name = "TERRAFORM_CLOUD"
  }
  profile = "rjs-mgmt"
}

locals {
  azs           = ["${var.region}a", "${var.region}b", "${var.region}c"]
  selected_vpcs = { for k, v in local.vpcs : k => v if v.account == var.environment && v.region == var.region }

  default_tags = {
    "automation:CreatedBy" = "Terraform Cloud"
    "Environment"          = var.environment
  }
  public_subnet_tags  = { Tier = "public" }
  private_subnet_tags = { Tier = "private" }
  intra_subnet_tags   = { Tier = "tgw" }
}

module "shared-vpc" {
  for_each = local.selected_vpcs
  source   = "./modules/shared-vpc"

  name       = each.key
  short_name = each.value.short_name
  cidr       = each.value.cidr_block
  azs        = local.azs

  share_private_subnets_with    = var.accounts[var.environment]
  share_deployment_subnets_with = var.accounts.deployment

  private_subnets    = each.value.private_subnets
  public_subnets     = each.value.public_subnets
  transitgw_subnets  = each.value.transitgw_subnets
  deployment_subnets = each.value.deployment_subnets

  default_tags        = local.default_tags
  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  intra_subnet_tags   = local.intra_subnet_tags

  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  one_nat_gateway_per_az = false
  single_nat_gateway     = true

  enable_flow_log                                 = false
  flow_log_destination_type                       = "s3"
  flow_log_destination_arn                        = ""
  create_flow_log_cloudwatch_log_group            = false
  create_flow_log_cloudwatch_iam_role             = false
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 1

  providers = {
    aws.workload   = aws.workload
    aws.deployment = aws.deployment
  }
}
