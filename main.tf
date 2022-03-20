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

#
# Tenant 1 - Tier 1 Router and Segments
# 

resource "nsxt_policy_tier1_gateway" "AVS01-Tier1-Tenant1" {
  description               = "AVS01-Tier1-Tenant1 provisioned by Brett"
  display_name              = "AVS01-Tier1-Tenant1"
  nsx_id                    = "AVS01-Tier1-Tenant1"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"

  tag {
    scope = var.module_tenant1
    tag   = "AVS01-Tier1-Tenant1"
  }
}


module "Tenant1_Segments" {
  source         = "./modules/tenant1_segments"
  segment_names  = ["Tenant1_Segment_1","Tenant1_Segment_2","Tenant1_Segment_3"]
  segment_IPs    = ["10.100.1.1/24","10.100.2.1/24","10.100.3.1/24"]
  segment_tenant = var.module_tenant1

  depends_on = [
    nsxt_policy_tier1_gateway.AVS01-Tier1-Tenant1
  ]
}

#
# Tenant 2 - Tier 1 Router and Segments
# 

resource "nsxt_policy_tier1_gateway" "AVS01-Tier1-Tenant2" {
  description               = "AVS01-Tier1-Tenant2 provisioned by Brett"
  display_name              = "AVS01-Tier1-Tenant2"
  nsx_id                    = "AVS01-Tier1-Tenant2"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"

  tag {
    scope = var.module_tenant2
    tag   = "AVS01-Tier1-Tenant2"
  }
}


module "Tenant2_Segments" {
  source         = "./modules/tenant2_segments"
  segment_names  = ["Tenant2_Segment_1","Tenant2_Segment_2","Tenant2_Segment_3"]
  segment_IPs    = ["10.110.1.1/24","10.110.2.1/24","10.110.3.1/24"]
  segment_tenant = var.module_tenant2

  depends_on = [
    nsxt_policy_tier1_gateway.AVS01-Tier1-Tenant2
  ]
} 

#
# Etc...
#