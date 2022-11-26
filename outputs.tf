output "vpcs" {
  value = { for k, v in module.vpc : v.vpc_id => {
    name     = v.name
    workload = k
    }
  }
}
