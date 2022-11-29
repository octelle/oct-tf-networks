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
  #azs                      = ["${var.region}a", "${var.region}b", "${var.region}c"]
  azs                      = ["eu-west1a", "eu-west1b", "eu-west1c"]
  subnets                  = ["private", "deployment", "public", "tgw"]
  cidrs = {
    "eu-west-1" = {
      dev = {
        apps = "10.2.0.0/16"
        core = "10.3.0.0/16"
      }
      stg = {
        apps       = "10.8.0.0/16"
        core       = "10.9.0.0/16"
      }
      prd = {
        deployment = "10.7.0.0/16"
        apps       = "10.8.0.0/16"
        core       = "10.9.0.0/16"
      }
    }
    "us-east-1" = {
      prd = {
        apps       = "10.0.0.0/16"
        core       = "10.1.0.0/16"
      }
    }
  }
  vpcs = { for k, v in try(local.cidrs["eu-west-1"]["prod"], {}) :  k => merge({ cidr = v }, zipmap(local.subnets, chunklist(cidrsubnets(v, 3, 3, 3, 12, 12, 12, 4, 4, 4, 12, 12, 12), 3))) }

  # ================================
  # OPTION 1
  # ================================

  vpcs3 = [{
      # EU production
      account = "prd",    region = "eu-west-1",    vpc = "apps",                cidr = "10.1.0.0/16"
      account = "prd",    region = "eu-west-1",    vpc = "core",                cidr = "10.2.0.0/16"
      account = "prd",    region = "eu-west-1",    vpc = "deployment",          cidr = "10.3.0.0/16"

      # US production
      account = "prd",    region = "us-east-1",    vpc = "apps",                cidr = "10.4.0.0/16"
      account = "prd",    region = "us-east-1",    vpc = "core",                cidr = "10.5.0.0/16"

      # Staging
      account = "stg",    region = "eu-west-1",    vpc = "apps",                cidr = "10.6.0.0/16"
      account = "stg",    region = "eu-west-1",    vpc = "core",                cidr = "10.7.0.0/16"

      # Dev
      account = "dev",    region = "eu-west-1",    vpc = "apps",                cidr = "10.8.0.0/16"
      account = "dev",    region = "eu-west-1",    vpc = "core",                cidr = "10.9.0.0/16"

      account = "dev",    region = "eu-west-1",    vpc = "apps-supplychain",    cidr = "10.10.0.0/16"
      account = "dev",    region = "eu-west-1",    vpc = "core-supplychain",    cidr = "10.11.0.0/16"
      
    },]

    # ---- subnets ---- # - /28 = 16 ips, /20 = 2000 ips, /19 = 8000 ips
    subnets3 = {

      #EU Production
      "prd-eu-west-1-apps" = {
        private_subnets     = ["10.1.0.0/19",   "10.1.32.0/19",   "10.1.64.0/19",]
        public_subnets      = ["10.1.112.0/20", "10.1.128.0/20",  "10.1.144.0/20",]
        deployment_subnets  = ["10.1.96.0/28",  "10.1.96.16/28",  "10.1.96.32/28",]
        transit_subnets     = ["10.1.160.0/28", "10.1.160.16/28", "10.1.160.32/28",]
      }
      "prd-eu-west-1-core" = {
        private_subnets     = ["10.2.0.0/19",   "10.2.32.0/19",   "10.2.64.0/19",]
        public_subnets      = ["10.2.112.0/20", "10.2.128.0/20",  "10.2.144.0/20",]
        deployment_subnets  = ["10.2.96.0/28",  "10.2.96.16/28",  "10.2.96.32/28",]
        transit_subnets     = ["10.2.160.0/28", "10.2.160.16/28", "10.2.160.32/28",]
      }
      "prd-eu-west-1-deployment" = {
        private_subnets     = ["10.3.0.0/19",   "10.3.32.0/19",   "10.3.64.0/19",]
        public_subnets      = ["10.3.112.0/20", "10.3.128.0/20",  "10.3.144.0/20",]
        transit_subnets     = ["10.3.160.0/28", "10.3.160.16/28", "10.3.160.32/28",]
      }

      #US Production
      "prd-us-east-1-apps" = {
        private_subnets     = ["10.4.0.0/19",   "10.4.32.0/19",   "10.4.64.0/19",]
        public_subnets      = ["10.4.112.0/20", "10.4.128.0/20",  "10.4.144.0/20",]
        deployment_subnets  = ["10.4.96.0/28",  "10.4.96.16/28",  "10.4.96.32/28",]
        transit_subnets     = ["10.4.160.0/28", "10.4.160.16/28", "10.4.160.32/28",]
      }
      "prd-us-east-1-core" = {
        private_subnets     = ["10.5.0.0/19",   "10.5.32.0/19",   "10.5.64.0/19",]
        public_subnets      = ["10.5.112.0/20", "10.5.128.0/20",  "10.5.144.0/20",]
        deployment_subnets  = ["10.5.96.0/28",  "10.5.96.16/28",  "10.5.96.32/28",]
        transit_subnets     = ["10.5.160.0/28", "10.5.160.16/28", "10.5.160.32/28",]
      }

      #Staging
      "stg-eu-west-1-apps" = {
        private_subnets     = ["10.6.0.0/19",   "10.6.32.0/19",   "10.6.64.0/19",]
        public_subnets      = ["10.6.112.0/20", "10.6.128.0/20",  "10.6.144.0/20",]
        deployment_subnets  = ["10.6.96.0/28",  "10.6.96.16/28",  "10.6.96.32/28",]
        transit_subnets     = ["10.6.160.0/28", "10.6.160.16/28", "10.6.160.32/28",]
      }
      "stg-eu-west-1-core" = {
        private_subnets     = ["10.7.0.0/19",   "10.7.32.0/19",   "10.7.64.0/19",]
        public_subnets      = ["10.7.112.0/20", "10.7.128.0/20",  "10.7.144.0/20",]
        deployment_subnets  = ["10.7.96.0/28",  "10.7.96.16/28",  "10.7.96.32/28",]
        transit_subnets     = ["10.7.160.0/28", "10.7.160.16/28", "10.7.160.32/28",]
      }

      # Dev
      "dev-eu-west-1-apps" = {
        private_subnets     = ["10.8.0.0/19",   "10.8.32.0/19",   "10.8.64.0/19",]
        public_subnets      = ["10.8.112.0/20", "10.8.128.0/20",  "10.8.144.0/20",]
        deployment_subnets  = ["10.8.96.0/28",  "10.8.96.16/28",  "10.8.96.32/28",]
        transit_subnets     = ["10.8.160.0/28", "10.8.160.16/28", "10.8.160.32/28",]
      }
      "dev-eu-west-1-core" = {
        private_subnets     = ["10.9.0.0/19",   "10.9.32.0/19",   "10.9.64.0/19",]
        public_subnets      = ["10.9.112.0/20", "10.9.128.0/20",  "10.9.144.0/20",]
        deployment_subnets  = ["10.9.96.0/28",  "10.9.96.16/28",  "10.9.96.32/28",]
        transit_subnets     = ["10.9.160.0/28", "10.9.160.16/28", "10.9.160.32/28",]
      }

      "dev-eu-west-1-apps-supplychain" = {
        private_subnets     = ["10.10.0.0/19",   "10.10.32.0/19",   "10.10.64.0/19",]
        public_subnets      = ["10.10.112.0/20", "10.10.128.0/20",  "10.10.144.0/20",]
        deployment_subnets  = ["10.10.96.0/28",  "10.10.96.16/28",  "10.10.96.32/28",]
        transit_subnets     = ["10.10.160.0/28", "10.10.160.16/28", "10.10.160.32/28",]
      }
      "dev-eu-west-1-core-supplychain" = {
        private_subnets     = ["10.11.0.0/19",   "10.11.32.0/19",   "10.11.64.0/19",]
        public_subnets      = ["10.11.112.0/20", "10.11.128.0/20",  "10.11.144.0/20",]
        deployment_subnets  = ["10.11.96.0/28",  "10.11.96.16/28",  "10.11.96.32/28",]
        transit_subnets     = ["10.11.160.0/28", "10.11.160.16/28", "10.11.160.32/28",]
      }
    }
    # ---- subnets ---- #
  

  # ================================
  # OPTION 2
  # ================================

  vpcs2 = {
    "eu-west-1" = {
      prod_account = {
        apps_vpc = {
          vpc_cidr            = "10.8.0.0/16"
          private_subnets     = ["10.8.0.0/19",   "10.8.32.0/19",   "10.8.64.0/19",]
          public_subnets      = ["10.8.112.0/20", "10.8.128.0/20",  "10.8.144.0/20",]
          deployment_subnets  = ["10.8.96.0/28",  "10.8.96.16/28",  "10.8.96.32/28",]
          transit_subnets     = ["10.8.160.0/28", "10.8.160.16/28", "10.8.160.32/28",]
        }
        core_vpc = {
          vpc_cidr            = "10.9.0.0/16"
          private_subnets     = ["10.9.0.0/19",   "10.9.32.0/19",   "10.9.64.0/19",]
          public_subnets      = ["10.9.112.0/20", "10.9.128.0/20",  "10.9.144.0/20",]
          deployment_subnets  = ["10.9.96.0/28",  "10.9.96.16/28",  "10.9.96.32/28",]
          transit_subnets     = ["10.9.160.0/28", "10.9.160.16/28", "10.9.160.32/28",]
        }
        deployment_vpc = {
          vpc_cidr            = "10.7.0.0/16"
          private_subnets     = ["10.7.0.0/19",   "10.7.32.0/19",   "10.7.64.0/19",]
          public_subnets      = ["10.7.112.0/20", "10.7.128.0/20",  "10.7.144.0/20",]
          transit_subnets     = ["10.7.160.0/28", "10.7.160.16/28", "10.7.160.32/28",]
        }
      }

      dev_account = {
        apps_vpc = {
          vpc_cidr            = "10.2.0.0/16"
          private_subnets     = ["10.2.0.0/19",   "10.2.32.0/19",   "10.2.64.0/19",]
          public_subnets      = ["10.2.112.0/20", "10.2.128.0/20",  "10.2.144.0/20",]
          deployment_subnets  = ["10.2.96.0/28",  "10.2.96.16/28",  "10.2.96.32/28",]
          transit_subnets     = ["10.2.96.0/28",  "10.2.96.16/28",  "10.2.96.32/28",] 
        }
        core_vpc = {
          vpc_cidr            = "10.3.0.0/16"
          private_subnets     = ["10.3.0.0/19",   "10.3.32.0/19",   "10.3.64.0/19",]
          public_subnets      = ["10.3.112.0/20", "10.3.128.0/20",  "10.3.144.0/20",]
          deployment_subnets  = ["10.3.96.0/28",  "10.3.96.16/28",  "10.3.96.32/28",]
          transit_subnets     = ["10.3.160.0/28", "10.3.160.16/28", "10.3.160.32/28",] 
        }

        apps_supplychain_vpc = {
          vpc_cidr            = "10.10.0.0/16"
          private_subnets     = ["10.10.0.0/19",   "10.10.32.0/19",   "10.10.64.0/19",]
          public_subnets      = ["10.10.112.0/20", "10.10.128.0/20",  "10.10.144.0/20",]
          deployment_subnets  = ["10.10.96.0/28",  "10.10.96.16/28",  "10.10.96.32/28",]
          transit_subnets     = ["10.10.96.0/28",  "10.10.96.16/28",  "10.10.96.32/28",] 
        }
        core_supplychain_vpc = {
          vpc_cidr            = "10.11.0.0/16"
          private_subnets     = ["10.11.0.0/19",   "10.11.32.0/19",   "10.11.64.0/19",]
          public_subnets      = ["10.11.112.0/20", "10.11.128.0/20",  "10.11.144.0/20",]
          deployment_subnets  = ["10.11.96.0/28",  "10.11.96.16/28",  "10.11.96.32/28",]
          transit_subnets     = ["10.11.160.0/28", "10.11.160.16/28", "10.11.160.32/28",] 
        }
      }
    }
    
    "us-east-1" = {
      prod_account = {
        apps_vpc = {
          vpc_cidr            = "10.8.0.0/16"
          private_subnets     = ["10.8.0.0/19",   "10.8.32.0/19",   "10.8.64.0/19",]
          public_subnets      = ["10.8.112.0/20", "10.8.128.0/20",  "10.8.144.0/20",]
          deployment_subnets  = ["10.8.96.0/28",  "10.8.96.16/28",  "10.8.96.32/28",]
          transit_subnets     = ["10.8.160.0/28", "10.8.160.16/28", "10.8.160.32/28",]
        }
        core_vpc = {
          vpc_cidr            = "10.9.0.0/16"
          private_subnets     = ["10.9.0.0/19",   "10.9.32.0/19",   "10.9.64.0/19",]
          public_subnets      = ["10.9.112.0/20", "10.9.128.0/20",  "10.9.144.0/20",]
          deployment_subnets  = ["10.9.96.0/28",  "10.9.96.16/28",  "10.9.96.32/28",]
          transit_subnets     = ["10.9.160.0/28", "10.9.160.16/28", "10.9.160.32/28",]
        }
      }
    }
  }
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


###############
# SSM Ansible stuff #
###############
resource "aws_ssm_document" "oct_ansible" {
  name          = "Oct-ApplyAnsiblePlaybooks"
  document_type = "Command"
  content       = file("ansible-ssm-doc.json")
  permissions = {
    type        = "Share"
    account_ids = "All"
  }
}
