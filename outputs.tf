output "vpcs" {
  value = { for k, v in module.vpc : v.vpc_id => {
    arn  = v.vpc_arn
    id   = v.vpc_id
    name = v.name
    }
  }
}

output "selected-private-subnets" {
  value = local.selected_private_subnets
}

output "private-subnets" {
  depends_on = [
    module.vpc
  ]

  value = { for k, v in data.aws_subnet.workload_subnet : k => {
    #vals = v
    arn  = v.arn
    name = v.tags.Name
    }
  }
}

output "resource-shares" {
  value = {
    workload   = resource.aws_ram_resource_share.vpc-shares-workload
    deployment = resource.aws_ram_resource_share.vpc-shares-deployment
  }
}

output "subnet-tags" {
  value = local.subnet_tags
}
