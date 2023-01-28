output "vpcs" {
  value = { for k, v in module.shared-vpc : v.vpc_id => {
    name   = v.name
    vpc_id = k
    }
  }
}
