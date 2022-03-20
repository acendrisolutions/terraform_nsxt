# terraform_nsxt
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

