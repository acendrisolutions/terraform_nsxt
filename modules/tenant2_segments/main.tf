# NSX-T Segment Module

terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

data "nsxt_policy_tier1_gateway" "tier1_router" {
  display_name = "AVS01-Tier1-Tenant2"
  }
 
data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "TNTxx-OVERLAY-TZ"
}
 

resource "nsxt_policy_segment" "segment" {
  count               = length(var.segment_names)  
  display_name        = var.segment_names[count.index]
  description         = "Terraform provisioned Segment"
  connectivity_path   = data.nsxt_policy_tier1_gateway.tier1_router.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  subnet {
    cidr = var.segment_IPs[count.index]
    # dhcp_ranges = ["10.197.7.193-10.197.7.200"]
  }
    tag {
    scope = var.segment_tenant
    tag   = var.segment_names[count.index]
  }
}

locals {
    segment_names = {
        for index, segment in nsxt_policy_segment.segment : 
        segment.display_name => segment.id
    }
}
 
# comment
