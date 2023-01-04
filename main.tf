provider "aws" {
  region = var.region
  default_tags {
    tags = local.default_tags
  }
  profile = "rjs"
}

locals {
  default_tags = {
    "automation:CreatedBy"         = "Terraform Cloud"
    "technical:TerraformWorkspace" = terraform.workspace
  }
  public_subnet_tags  = { Tier = "public" }
  private_subnet_tags = { Tier = "private" }
  intra_subnet_tags   = { Tier = "tgw" }
  #flow_log_destination_arn = "arn:aws:s3:::bp-vpc-flowlogs-bucket"
  azs = ["${var.region}a", "${var.region}b", "${var.region}c"]

  selected_vpcs = { for k, v in local.vpcs : k => v if v.account == var.environment && v.region == var.region }
}

#VPCs defined in locals.tf, selection for each run controlled by supplied var.environment and var.region
module "vpc" {
  for_each = local.selected_vpcs
  source   = "terraform-aws-modules/vpc/aws"
  version  = "~>3.18.1"

  name = each.key
  cidr = each.value.cidr_block
  azs  = local.azs

  #using list comprehensions to build lists of cidr blocks and names
  private_subnets      = concat([for name, cidr in each.value.private_subnets : cidr], [for name, cidr in each.value.deployment_subnets : cidr])
  private_subnet_names = concat([for name, cidr in each.value.private_subnets : name], [for name, cidr in each.value.deployment_subnets : name])
  public_subnets       = [for name, cidr in each.value.public_subnets : cidr]
  public_subnet_names  = [for name, cidr in each.value.public_subnets : name]
  intra_subnets        = [for name, cidr in each.value.transitgw_subnets : cidr]
  intra_subnet_names   = [for name, cidr in each.value.transitgw_subnets : name]

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  intra_subnet_tags   = local.intra_subnet_tags

  enable_nat_gateway     = false
  enable_vpn_gateway     = false
  one_nat_gateway_per_az = false
  single_nat_gateway     = true

  enable_flow_log = false
}


###############
# SSM Ansible stuff #
###############
#resource "aws_ssm_document" "oct_ansible" {
#  name          = "Oct-ApplyAnsiblePlaybooks"
#  document_type = "Command"
#  content       = file("ansible-ssm-doc.json")
#  permissions = {
#    type        = "Share"
#    account_ids = "All"
#  }
#}
