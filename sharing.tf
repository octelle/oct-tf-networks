######################
# Share Subnets      #
######################
locals {
  selected_private_subnets = flatten([for k, v in local.selected_vpcs : [
    for name, cidr in v.private_subnets : {
      subnet_name = name
      vpc_name    = k
    }
  ]])
  selected_deployment_subnets = flatten([for k, v in local.selected_vpcs : [
    for name, cidr in v.deployment_subnets : {
      subnet_name = name
      vpc_name    = k
    }
  ]])
}

#Subnet data
data "aws_subnet" "workload_subnet" {
  depends_on = [
    module.vpc
  ]

  for_each = { for subnet in local.selected_private_subnets : subnet.subnet_name => subnet }

  filter {
    name   = "tag:Name"
    values = [each.value.subnet_name]
  }
}

data "aws_subnet" "deployment_subnet" {
  depends_on = [
    module.vpc
  ]

  for_each = { for subnet in local.selected_deployment_subnets : subnet.subnet_name => subnet }

  filter {
    name   = "tag:Name"
    values = [each.value.subnet_name]
  }
}

#workloads
#the resource share for each VPC created
resource "aws_ram_resource_share" "vpc-shares-workload" {
  for_each                  = local.selected_vpcs
  name                      = "${each.key}-workload-resource-share"
  allow_external_principals = false
}

#assign principals to VPC resource shares
resource "aws_ram_principal_association" "vpc-shares-workload-principal" {
  for_each           = local.selected_vpcs
  principal          = var.accounts[var.environment]
  resource_share_arn = aws_ram_resource_share.vpc-shares-workload[each.key].arn
}

#subnet share
resource "aws_ram_resource_association" "vpc-shares-workload-subnets" {
  for_each           = { for subnet in local.selected_private_subnets : subnet.subnet_name => subnet }
  resource_arn       = data.aws_subnet.workload_subnet[each.value.subnet_name].arn
  resource_share_arn = aws_ram_resource_share.vpc-shares-workload[each.value.vpc_name].arn
}

#deployment
#the resource share for each VPC created
resource "aws_ram_resource_share" "vpc-shares-deployment" {
  for_each                  = local.selected_vpcs
  name                      = "${each.key}-deployment-resource-share"
  allow_external_principals = false
}

#assign principals to VPC resource shares
resource "aws_ram_principal_association" "vpc-shares-deployment-principal" {
  for_each           = local.selected_vpcs
  principal          = var.accounts.deployment
  resource_share_arn = aws_ram_resource_share.vpc-shares-deployment[each.key].arn
}

#subnet share
resource "aws_ram_resource_association" "vpc-shares-deployment-subnets" {
  for_each           = { for subnet in local.selected_deployment_subnets : subnet.subnet_name => subnet }
  resource_arn       = data.aws_subnet.deployment_subnet[each.value.subnet_name].arn
  resource_share_arn = aws_ram_resource_share.vpc-shares-deployment[each.value.vpc_name].arn
}

######################
# Share Tags         #
######################

#the specific workload account
provider "aws" {
  alias   = "workload"
  region  = var.region
  profile = "rjs"
  assume_role {
    role_arn     = "arn:aws:iam::${var.accounts[var.environment]}:role/TerraformCloudRole"
    session_name = "TERRAFORM_CLOUD"
  }
}

#the deployment account
provider "aws" {
  alias   = "deployment"
  region  = var.region
  profile = "rjs"
  assume_role {
    role_arn     = "arn:aws:iam::${var.accounts.deployment}:role/TerraformCloudRole"
    session_name = "TERRAFORM_CLOUD"
  }
}

locals {
  all_private_subnet_tags = merge(local.private_subnet_tags, local.default_tags)

  #construct vpc tags to share
  vpc_other_tags = flatten([for s in module.vpc : [for k, v in local.default_tags : { resource = s.vpc_id, key = k, value = v }]])
  vpc_name_tags  = [for vpc in module.vpc : { resource = vpc.vpc_id, key = "Name", value = vpc.name }]

  #construct workload subnet tags to share
  subnet_other_tags = flatten([for s in data.aws_subnet.workload_subnet : [for k, v in local.all_private_subnet_tags : { resource = s.id, key = k, value = v }]])
  subnet_name_tags  = [for subnet in local.selected_private_subnets : { resource = data.aws_subnet.workload_subnet[subnet.subnet_name].id, key = "Name", value = subnet.subnet_name }]
  subnet_tags       = concat(local.subnet_other_tags, local.subnet_name_tags, local.vpc_other_tags, local.vpc_name_tags)

  #construct deployment subnet tags to share
  deployment_subnet_other_tags = flatten([for s in data.aws_subnet.deployment_subnet : [for k, v in local.all_private_subnet_tags : { resource = s.id, key = k, value = v }]])
  deployment_subnet_name_tags  = [for subnet in local.selected_deployment_subnets : { resource = data.aws_subnet.deployment_subnet[subnet.subnet_name].id, key = "Name", value = subnet.subnet_name }]
  deployment_subnet_tags       = concat(local.deployment_subnet_other_tags, local.deployment_subnet_name_tags, local.vpc_other_tags, local.vpc_name_tags)
}

resource "aws_ec2_tag" "tag-workload" {
  provider    = aws.workload
  count       = length(local.subnet_tags)
  resource_id = local.subnet_tags[count.index].resource
  key         = local.subnet_tags[count.index].key
  value       = local.subnet_tags[count.index].value
  depends_on  = [aws_ram_resource_association.vpc-shares-workload-subnets, aws_ram_resource_association.vpc-shares-deployment-subnets]
}

resource "aws_ec2_tag" "tag-deployment" {
  provider    = aws.deployment
  count       = length(local.deployment_subnet_tags)
  resource_id = local.deployment_subnet_tags[count.index].resource
  key         = local.deployment_subnet_tags[count.index].key
  value       = local.deployment_subnet_tags[count.index].value
  depends_on  = [aws_ram_resource_association.vpc-shares-workload-subnets, aws_ram_resource_association.vpc-shares-deployment-subnets]
}
