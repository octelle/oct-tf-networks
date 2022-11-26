provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "automation:CreatedBy"         = "Terraform Cloud"
      "technical:TerraformWorkspace" = terraform.workspace
    }
  }
}

#######################################
# Set VPC Cidr ranges, account IDs... #
#######################################
locals {
  azs                      = ["${var.region}a", "${var.region}b", "${var.region}c"]
  subnets                  = ["private", "deployment", "public", "tgw"]
  cidrs = {
    "eu-west-1" = {
      dev = {
        apps = "10.2.0.0/16"
        core = "10.3.0.0/16"
      }
      stg = {
        apps = "10.5.0.0/16"
        core = "10.6.0.0/16"
      }
      prd = {
        deployment = "10.7.0.0/16"
        apps       = "10.8.0.0/16"
        core       = "10.9.0.0/16"
      }
    }
  }
  vpcs = { for k, v in try(local.cidrs[var.region][var.environment], {}) :
  k => merge({ cidr = v }, zipmap(local.subnets, chunklist(cidrsubnets(v, 3, 3, 3, 12, 12, 12, 4, 4, 4, 12, 12, 12), 3))) }
}

###############
# Create VPCs #
###############
module "vpc" {
  for_each = local.vpcs
  source   = "terraform-aws-modules/vpc/aws"
  version  = "~>3.18.1"

  name = "oct-${var.environment}-${each.key}"
  cidr = each.value.cidr

  azs                  = local.azs
  private_subnets      = concat(each.value.private, each.value.deployment)
  private_subnet_names = [for i in setproduct(["bp-${var.environment}-${each.key}-private", "bp-${var.environment}-${each.key}-deployment"], local.azs) : join("-", i)]
  public_subnets       = each.value.public
  intra_subnets        = each.value.tgw
  intra_subnet_suffix  = "tgw"

  public_subnet_tags = {
    Tier = "public"
  }
  private_subnet_tags = {
    Tier = "private"
  }
  intra_subnet_tags = {
    Tier = "tgw"
  }

  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  one_nat_gateway_per_az = false
  single_nat_gateway     = true

  enable_flow_log                                 = false
}
