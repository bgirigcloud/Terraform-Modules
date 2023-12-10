Terraform Network Module
This module makes it easy to set up a new VPC Network in GCP by defining your network and subnet ranges in a concise syntax.

It supports creating:

A Google Virtual Private Network (VPC)
Subnets within the VPC
Secondary ranges for the subnets (if applicable)
Sub modules are provided for creating individual vpc, subnets, and routes. See the modules directory for the various sub modules usage.

Compatibility
This module is meant for use with Terraform 0.13+ and tested using Terraform 1.0+. If you find incompatibilities using Terraform >=0.13, please open an issue.

If you haven't upgraded and need a Terraform 0.12.x-compatible version of this module, the last released version intended for Terraform 0.12.x is 2.6.0.

Usage
You can go to the examples folder, however the usage of the module could be like this in your own main.tf file:

module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 6.0"

    project_id   = "<PROJECT ID>"
    network_name = "example-vpc"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-west1"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "us-west1"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "This subnet has a description"
        },
        {
            subnet_name               = "subnet-03"
            subnet_ip                 = "10.10.30.0/24"
            subnet_region             = "us-west1"
            subnet_flow_logs          = "true"
            subnet_flow_logs_interval = "INTERVAL_10_MIN"
            subnet_flow_logs_sampling = 0.7
            subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
        }
    ]

    secondary_ranges = {
        subnet-01 = [
            {
                range_name    = "subnet-01-secondary-01"
                ip_cidr_range = "192.168.64.0/24"
            },
        ]

        subnet-02 = []
    }

    routes = [
        {
            name                   = "egress-internet"
            description            = "route through IGW to access internet"
            destination_range      = "0.0.0.0/0"
            tags                   = "egress-inet"
            next_hop_internet      = "true"
        },
        {
            name                   = "app-proxy"
            description            = "route through proxy to reach app"
            destination_range      = "10.50.10.0/24"
            tags                   = "app-proxy"
            next_hop_instance      = "app-proxy-instance"
            next_hop_instance_zone = "us-west1-a"
        },
    ]
}
Then perform the following commands on the root folder:

terraform init to get the plugins
terraform plan to see the infrastructure plan
terraform apply to apply the infrastructure build
terraform destroy to destroy the built infrastructure
Inputs
Name	Description	Type	Default	Required
auto_create_subnetworks	When set to true, the network is created in 'auto subnet mode' and it will create a subnet for each region automatically across the 10.128.0.0/9 address range. When set to false, the network is created in 'custom subnet mode' so the user can explicitly connect subnetwork resources.	bool	false	no
delete_default_internet_gateway_routes	If set, ensure that all routes within the network specified whose names begin with 'default-route' and with a next hop of 'default-internet-gateway' are deleted	bool	false	no
description	An optional description of this resource. The resource must be recreated to modify this field.	string	""	no
firewall_rules	List of firewall rules	any	[]	no
mtu	The network MTU (If set to 0, meaning MTU is unset - defaults to '1460'). Recommended values: 1460 (default for historic reasons), 1500 (Internet default), or 8896 (for Jumbo packets). Allowed are all values in the range 1300 to 8896, inclusively.	number	0	no
network_name	The name of the network being created	string	n/a	yes
project_id	The ID of the project where this VPC will be created	string	n/a	yes
routes	List of routes being created in this VPC	list(map(string))	[]	no
routing_mode	The network routing mode (default 'GLOBAL')	string	"GLOBAL"	no
secondary_ranges	Secondary ranges that will be used in some of the subnets	map(list(object({ range_name = string, ip_cidr_range = string })))	{}	no
shared_vpc_host	Makes this project a Shared VPC host if 'true' (default 'false')	bool	false	no
subnets	The list of subnets being created	list(map(string))	n/a	yes
Outputs
Name	Description
network	The created network
network_id	The ID of the VPC being created
network_name	The name of the VPC being created
network_self_link	The URI of the VPC being created
project_id	VPC project id
route_names	The route names associated with this VPC
subnets	A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets.
subnets_flow_logs	Whether the subnets will have VPC flow logs enabled
subnets_ids	The IDs of the subnets being created
subnets_ips	The IPs and CIDRs of the subnets being created
subnets_names	The names of the subnets being created
subnets_private_access	Whether the subnets will have access to Google API's without a public IP
subnets_regions	The region where the subnets will be created
subnets_secondary_ranges	The secondary ranges associated with these subnets
subnets_self_links	The self-links of subnets being created
Subnet Inputs
The subnets list contains maps, where each object represents a subnet. Each map has the following inputs (please see examples folder for additional references):

Name	Description	Type	Default	Required
subnet_name	The name of the subnet being created	string	-	yes
subnet_ip	The IP and CIDR range of the subnet being created	string	-	yes
subnet_region	The region where the subnet will be created	string	-	yes
subnet_private_access	Whether this subnet will have private Google access enabled	string	"false"	no
subnet_flow_logs	Whether the subnet will record and send flow log data to logging	string	"false"	no
Route Inputs
The routes list contains maps, where each object represents a route. For the next_hop_* inputs, only one is possible to be used in each route. Having two next_hop_* inputs will produce an error. Each map has the following inputs (please see examples folder for additional references):

Name	Description	Type	Default	Required
name	The name of the route being created	string	-	no
description	The description of the route being created	string	-	no
tags	The network tags assigned to this route. This is a list in string format. Eg. "tag-01,tag-02"	string	-	yes
destination_range	The destination range of outgoing packets that this route applies to. Only IPv4 is supported	string	-	yes
next_hop_internet	Whether the next hop to this route will the default internet gateway. Use "true" to enable this as next hop	string	"false"	yes
next_hop_ip	Network IP address of an instance that should handle matching packets	string	-	yes
next_hop_instance	URL or name of an instance that should handle matching packets. If just name is specified "next_hop_instance_zone" is required	string	-	yes
next_hop_instance_zone	The zone of the instance specified in next_hop_instance. Only required if next_hop_instance is specified as a name	string	-	no
next_hop_vpn_tunnel	URL to a VpnTunnel that should handle matching packets	string	-	yes
priority	The priority of this route. Priority is used to break ties in cases where there is more than one matching route of equal prefix length. In the case of two routes with equal prefix length, the one with the lowest-numbered priority value wins	string	"1000"	yes
Requirements
Installed Software
Terraform ~> 0.12.6
Terraform Provider for GCP ~> 2.19
Terraform Provider for GCP Beta ~> 2.19
gcloud >243.0.0
Configure a Service Account
In order to execute this module you must have a Service Account with the following roles:

roles/compute.networkAdmin on the organization or folder
If you are going to manage a Shared VPC, you must have either:

roles/compute.xpnAdmin on the organization
roles/compute.xpnAdmin on the folder (beta)
Enable API's
In order to operate with the Service Account you must activate the following API on the project where the Service Account was created:

Compute Engine API - compute.googleapis.com
Contributing
Refer to the contribution guidelines for information on contributing to this module.
