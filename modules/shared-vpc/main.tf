
#-----------------------------------------------------
# VPC Creation
#-----------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>3.18.1"

  name     = var.name
  cidr     = var.cidr
  azs      = var.azs
  vpc_tags = { ShortName = var.short_name }

  #using list comprehensions to build lists of cidr blocks and names
  private_subnets      = concat([for name, cidr in var.private_subnets : cidr], [for name, cidr in var.deployment_subnets : cidr])
  private_subnet_names = concat([for name, cidr in var.private_subnets : name], [for name, cidr in var.deployment_subnets : name])
  public_subnets       = [for name, cidr in var.public_subnets : cidr]
  public_subnet_names  = [for name, cidr in var.public_subnets : name]
  intra_subnets        = [for name, cidr in var.transitgw_subnets : cidr]
  intra_subnet_names   = [for name, cidr in var.transitgw_subnets : name]

  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags
  intra_subnet_tags   = var.intra_subnet_tags

  enable_nat_gateway     = var.enable_nat_gateway
  enable_vpn_gateway     = var.enable_vpn_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  single_nat_gateway     = var.single_nat_gateway

  enable_flow_log                                 = var.enable_flow_log
  flow_log_destination_type                       = var.flow_log_destination_type
  flow_log_destination_arn                        = var.flow_log_destination_arn
  create_flow_log_cloudwatch_log_group            = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role             = var.create_flow_log_cloudwatch_iam_role
  flow_log_max_aggregation_interval               = var.flow_log_max_aggregation_interval
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days
}

#-----------------------------------------------------
# Subnet data lookups for Id and ARN
#-----------------------------------------------------
# subnet data for workload subnets (used to lookup Id and ARN)
data "aws_subnet" "workload_subnet" {
  depends_on = [module.vpc]
  for_each   = { for name, cidr in var.private_subnets : name => cidr }
  filter {
    name   = "tag:Name"
    values = [each.key]
  }
}

# subnet data for deployment subnets (used to lookup Id and ARN)
data "aws_subnet" "deployment_subnet" {
  depends_on = [module.vpc]
  for_each   = { for name, cidr in var.deployment_subnets : name => cidr }
  filter {
    name   = "tag:Name"
    values = [each.key]
  }
}

#-----------------------------------------------------
# Share private workload Subnets to workload account
#-----------------------------------------------------
# a resource share for each VPC created
resource "aws_ram_resource_share" "vpc-shares-workload" {
  name                      = "${var.name}-workload-resource-share"
  allow_external_principals = false
}

# assign principals (accounts) to resource shares
resource "aws_ram_principal_association" "vpc-shares-workload-principal" {
  principal          = var.share_private_subnets_with
  resource_share_arn = aws_ram_resource_share.vpc-shares-workload.arn
}

# assign subnets to resource shares
resource "aws_ram_resource_association" "vpc-shares-workload-subnets" {
  for_each           = { for name, cidr in var.private_subnets : name => cidr }
  resource_arn       = data.aws_subnet.workload_subnet[each.key].arn
  resource_share_arn = aws_ram_resource_share.vpc-shares-workload.arn
}

#-----------------------------------------------------
# Share deployment Subnets to deployment account
#-----------------------------------------------------
# a resource share for each VPC created
resource "aws_ram_resource_share" "vpc-shares-deployment" {
  name                      = "${var.name}-deployment-resource-share"
  allow_external_principals = false
}

# assign principals (accounts) to resource shares
resource "aws_ram_principal_association" "vpc-shares-deployment-principal" {
  principal          = var.share_deployment_subnets_with
  resource_share_arn = aws_ram_resource_share.vpc-shares-deployment.arn
}

# assign subnets to resource shares
resource "aws_ram_resource_association" "vpc-shares-deployment-subnets" {
  for_each           = { for name, cidr in var.deployment_subnets : name => cidr }
  resource_arn       = data.aws_subnet.deployment_subnet[each.key].arn
  resource_share_arn = aws_ram_resource_share.vpc-shares-deployment.arn
}

#-----------------------------------------------------
# Tag sharing
#-----------------------------------------------------
locals {
  all_private_subnet_tags = merge(var.private_subnet_tags, var.default_tags)

  #construct vpc tags to share
  vpc_default_tags = [for k, v in var.default_tags : { resource = module.vpc.vpc_id, key = k, value = v }]
  vpc_name_tags = [
    { resource = module.vpc.vpc_id, key = "Name", value = var.name },
    { resource = module.vpc.vpc_id, key = "ShortName", value = var.short_name }
  ]

  #construct workload subnet tags to share
  subnet_other_tags = flatten([for s in data.aws_subnet.workload_subnet : [for k, v in local.all_private_subnet_tags : { resource = s.id, key = k, value = v }]])
  subnet_name_tags  = [for subnet_name, cidr in var.private_subnets : { resource = data.aws_subnet.workload_subnet[subnet_name].id, key = "Name", value = subnet_name }]
  workload_tags     = concat(local.subnet_other_tags, local.subnet_name_tags, local.vpc_default_tags, local.vpc_name_tags)

  #construct deployment subnet tags to share
  deployment_subnet_other_tags = flatten([for s in data.aws_subnet.deployment_subnet : [for k, v in local.all_private_subnet_tags : { resource = s.id, key = k, value = v }]])
  deployment_subnet_name_tags  = [for subnet_name, cidr in var.deployment_subnets : { resource = data.aws_subnet.deployment_subnet[subnet_name].id, key = "Name", value = subnet_name }]
  deployment_tags              = concat(local.deployment_subnet_other_tags, local.deployment_subnet_name_tags, local.vpc_default_tags, local.vpc_name_tags)
}

#------ Share tags to workload account ------
resource "aws_ec2_tag" "tag-workload" {
  provider    = aws.workload
  count       = length(local.workload_tags)
  resource_id = local.workload_tags[count.index].resource
  key         = local.workload_tags[count.index].key
  value       = local.workload_tags[count.index].value
  depends_on  = [aws_ram_resource_association.vpc-shares-workload-subnets, aws_ram_resource_association.vpc-shares-deployment-subnets]
}

#------ Share tags to deployment account ------
resource "aws_ec2_tag" "tag-deployment" {
  provider    = aws.deployment
  count       = length(local.deployment_tags)
  resource_id = local.deployment_tags[count.index].resource
  key         = local.deployment_tags[count.index].key
  value       = local.deployment_tags[count.index].value
  depends_on  = [aws_ram_resource_association.vpc-shares-workload-subnets, aws_ram_resource_association.vpc-shares-deployment-subnets]
}
