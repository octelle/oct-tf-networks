locals {
  #================
  # VPCs
  #================
  # Generate subnets with:
  #  echo 'cidrsubnets("10.0.0.0/16", 3, 3, 3, 4, 4, 4, 12, 12, 12, 12, 12, 12)' | terraform console
  vpcs = {
    #---------------------------------------------------------------------
    #EU Production
    #---------------------------------------------------------------------
    "prd-apps-eu-west-1" = {
      account = "prd"
      vpc     = "apps"
      region  = "eu-west-1"

      cidr_block = "10.1.0.0/16"
      private_subnets = {
        "prd-apps-eu-west-1-private-1a" : "10.1.0.0/19"
        "prd-apps-eu-west-1-private-1b" : "10.1.32.0/19"
        "prd-apps-eu-west-1-private-1c" : "10.1.64.0/19"
      }
      public_subnets = {
        "prd-apps-eu-west-1-public-1a" : "10.1.96.0/20"
        "prd-apps-eu-west-1-public-1b" : "10.1.112.0/20"
        "prd-apps-eu-west-1-public-1c" : "10.1.128.0/20"
      }
      transitgw_subnets = {
        "prd-apps-eu-west-1-tgw-1a" : "10.1.144.0/28"
        "prd-apps-eu-west-1-tgw-1b" : "10.1.144.16/28"
        "prd-apps-eu-west-1-tgw-1c" : "10.1.144.32/28"
      }
      deployment_subnets = {
        "prd-apps-eu-west-1-deployment-1a" : "10.1.144.48/28"
        "prd-apps-eu-west-1-deployment-1b" : "10.1.144.64/28"
        "prd-apps-eu-west-1-deployment-1c" : "10.1.144.80/28"
      }
    }

    "prd-deployment-eu-west-1" = {
      account = "prd"
      vpc     = "deployment"
      region  = "eu-west-1"

      cidr_block = "10.3.0.0/16"
      private_subnets = {
        "prd-deployment-eu-west-1-private-1a" : "10.3.0.0/19"
        "prd-deployment-eu-west-1-private-1b" : "10.3.32.0/19"
        "prd-deployment-eu-west-1-private-1c" : "10.3.64.0/19"
      }
      public_subnets = {
        "prd-deployment-eu-west-1-public-1a" : "10.3.96.0/20"
        "prd-deployment-eu-west-1-public-1b" : "10.3.112.0/20"
        "prd-deployment-eu-west-1-public-1c" : "10.3.128.0/20"
      }
      transitgw_subnets = {
        "prd-deployment-eu-west-1-tgw-1a" : "10.3.144.0/28"
        "prd-deployment-eu-west-1-tgw-1b" : "10.3.144.16/28"
        "prd-deployment-eu-west-1-tgw-1c" : "10.3.144.32/28"
      }
      deployment_subnets = {
        #no deployment subnets in deployment VPC
      }
    }

    #---------------------------------------------------------------------
    #Dev (EU Only)
    #---------------------------------------------------------------------
    "dev-apps-eu-west-1" = {
      account = "dev"
      vpc     = "apps"
      region  = "eu-west-1"

      cidr_block = "10.7.0.0/16"
      private_subnets = {
        "dev-apps-eu-west-1-private-1a" : "10.7.0.0/19"
        "dev-apps-eu-west-1-private-1b" : "10.7.32.0/19"
        "dev-apps-eu-west-1-private-1c" : "10.7.64.0/19"
      }
      public_subnets = {
        "dev-apps-eu-west-1-public-1a" : "10.7.96.0/20"
        "dev-apps-eu-west-1-public-1b" : "10.7.112.0/20"
        "dev-apps-eu-west-1-public-1c" : "10.7.128.0/20"
      }
      transitgw_subnets = {
        "dev-apps-eu-west-1-tgw-1a" : "10.7.144.0/28"
        "dev-apps-eu-west-1-tgw-1b" : "10.7.144.16/28"
        "dev-apps-eu-west-1-tgw-1c" : "10.7.144.32/28"
      }
      deployment_subnets = {
        "dev-apps-eu-west-1-deployment-1a" : "10.7.144.48/28"
        "dev-apps-eu-west-1-deployment-1b" : "10.7.144.64/28"
        "dev-apps-eu-west-1-deployment-1c" : "10.7.144.80/28"
      }
    }
  }
}
