terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

provider "nsxt" {
  host                  = var.nsx_manager
  username              = var.nsx_username
  password              = var.nsx_password
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

data "nsxt_policy_edge_cluster" "EC" {
  display_name = "TNT67-CLSTR"
}

data "nsxt_policy_tier0_gateway" "T0" {
  display_name = "TNT67-T0"
}

data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "TNT67-OVERLAY-TZ"
}
 

resource "nsxt_policy_tier1_gateway" "AVS01-Tier1-Terraform" {
  description               = "AVS01-Tier1-Terraform provisioned by Brett"
  display_name              = "AVS01-Tier1-Terraform"
  nsx_id                    = "predefined_id"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"

  tag {
    scope = var.module_tenant
    tag   = "AVS01-Tier1-Terraform"
  }
}


module "Terraform_Segments" {
  source         = "./modules/segments"
  for_each = {for inst in local.segment_names_list : inst.local_id => inst}
  segment_names  = each.value.segment_names
  segment_IPs    = ["10.201.1.1/24","10.201.2.1/24","10.201.3.1/24"]
  segment_tenant = var.module_tenant

  depends_on = [
    nsxt_policy_tier1_gateway.AVS01-Tier1-Terraform
  ]
}

locals {
  segment_names_csv=file("./modules/segments/segment_names_csv.csv")
  segment_names_list=csvdecode(local.segment_names_csv)

} 

