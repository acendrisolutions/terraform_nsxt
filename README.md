Infrastructure as Code: Using Terraform and NSX-T to build Azure VMWare networks from code.

https://www.acendri-solutions.com/post/infrastructure-as-code-using-terraform-and-nsx-t-to-deploy-avs-networking-in-code


A lot of companies have been looking at Azure VMWare as a Service (AVS) to help them quickly migrate their on-prem virtual machines to the cloud. It can be seen as a shortcut to cloud entry without having to migrate your current vSphere hosts to native cloud and retrain your entire server team. 

That sounds great but it also means that you could lose some of the most appealing aspects of cloud, like Infrastructure as Code. Don't worry, we can still use Terraform in combination with NSX-T to build our cloud data center network in code. 

The Design:

In this example, we will create a 3 tier DevOps workflow based network topology with four tenants. A shared tenant for common services like Domain Controllers and tools, and three tenants for the application environments. 

Our NSX-T network will have the default AVS created Tier 0 router to peer with native Azure and will use Tier 1 routers to create the tenant separation between environments.. 

The Plan:

 I want to create a Terraform script that will accomplish the following tasks:

    Create a T1 gateway logical router per tenant

    Automatically create the tenant segments from a list or spreadsheet of values.

I am going to structure my code so that the main.tf file contains each of the Tier 1 gateways and calls an independent module that builds the tenant segments based on a list of values entered into the main file. The location of the NSX-T manager URL, the username and password will all be kept in the variables file.

The Code:

You can find the source code for this script at https://github.com/acendrisolutions/terraform_nsxt 

Before we can create the T1 routers, we need to identify the edge cluster, tier0 router, and transport overlay. These can be found by looking through the NSX-T networking.

data "nsxt_policy_edge_cluster" "EC" {
  display_name = "TNTXX-CLSTR"
}

data "nsxt_policy_tier0_gateway" "T0" {
  display_name = "TNTXX-T0"
}

data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "TNTXX-OVERLAY-TZ"
}

The next step is to build out the Tier 1 router. We will advertise both static and connected routes from these virtual routers.

resource "nsxt_policy_tier1_gateway" "AVS01-Tier1-Tenant1" {
  description               = "AVS01-Tier1-Tenant1 provisioned by Brett"
  display_name              = "AVS01-Tier1-Tenant1"
  nsx_id                    = "predefined_id"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"

Now we need to create the modules files to auto generate our segments. These modules will use count and for statements to create loops building segments until the data list provided in our main.tf file is exhausted.  


resource "nsxt_policy_segment" "segment" {
  count               = length(var.segment_names)  
  display_name        = var.segment_names[count.index]
  description         = "Terraform provisioned Segment"
  connectivity_path   = data.nsxt_policy_tier1_gateway.tier1_router.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  subnet {
    cidr = var.segment_IPs[count.index]
  }
}

locals {
    segment_names = {
        for index, segment in nsxt_policy_segment.segment : 
        segment.display_name => segment.id
    }
}

 

We will call these segment modules in our main.tf. This is also the time to provide our segment name and IP address data. 

(Eventually, I want to get this working by importing csv values from an attached spreadsheet but for now I have this working by writing out a comma separated data array.)

module "Tenant1_Segments" {
  source         = "./modules/tenant1_segments"
  segment_names  = ["Tenant1_Segment_1","Tenant1_Segment_2","Tenant1_Segment_3"]
  segment_IPs    = ["10.100.1.1/24","10.100.2.1/24","10.100.3.1/24"]
  segment_tenant = var.module_tenant1

  depends_on = [
    nsxt_policy_tier1_gateway.AVS01-Tier1-Tenant1
  ]
}

To see the complete syntax for this Terraform deployment check out the source code on GIThub: https://github.com/acendrisolutions/terraform_nsxt 

The Results:

To deploy this follow the standard Terraform deployment steps: 

    terraform init

    terraform plan

    terraform apply

After the successful Terraform deployment, I have logged into NSX manger and can see find that the code worked as expected. 

According to the example code, I have deployed two tier 1 routers with 3 segments each. 

This code can easily be scaled to match whatever your requirements are. If you have 4 tenants or 40. If you have 10 vlans per tenant or 100. Just copy the scripts, update some variable names, and add the segment data values.

Have fun!

More Information:

https://blogs.vmware.com/networkvirtualization/2018/04/nsx-t-automation-with-terraform.html/ 

https://registry.terraform.io/providers/vmware/nsxt/latest/docs/guides/vmc 

https://azure.microsoft.com/en-us/services/azure-vmware/ 

https://microsoft.github.io/PartnerResources/azure/infrastructure/azure-vmware-solution 