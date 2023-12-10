/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/******************************************
	VPC configuration
 *****************************************/
module "vpc" {
  source                                 = "./modules/vpc"
  network_name                           = var.network_name
  auto_create_subnetworks                = var.auto_create_subnetworks
  routing_mode                           = var.routing_mode
  project_id                             = var.project_id
  description                            = var.description
  shared_vpc_host                        = var.shared_vpc_host
  delete_default_internet_gateway_routes = var.delete_default_internet_gateway_routes
  mtu                                    = var.mtu
}

/******************************************
	Subnet configuration
 *****************************************/
module "subnets" {
  source           = "./modules/subnets"
  project_id       = var.project_id
  network_name     = module.vpc.network_name
  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges
}

/******************************************
	Routes
 *****************************************/
module "routes" {
  source            = "./modules/routes"
  project_id        = var.project_id
  network_name      = module.vpc.network_name
  routes            = var.routes
  module_depends_on = [module.subnets.subnets]
}

/******************************************
	Firewall rules
 *****************************************/
locals {
  rules = [
    for f in var.firewall_rules : {
      name                    = f.name
      direction               = f.direction
      priority                = lookup(f, "priority", null)
      description             = lookup(f, "description", null)
      ranges                  = lookup(f, "ranges", null)
      source_tags             = lookup(f, "source_tags", null)
      source_service_accounts = lookup(f, "source_service_accounts", null)
      target_tags             = lookup(f, "target_tags", null)
      target_service_accounts = lookup(f, "target_service_accounts", null)
      allow                   = lookup(f, "allow", [])
      deny                    = lookup(f, "deny", [])
      log_config              = lookup(f, "log_config", null)
    }
  ]
}

module "firewall_rules" {
  source       = "./modules/firewall-rules"
  project_id   = var.project_id
  network_name = module.vpc.network_name
  rules        = local.rules
}

module "test-vpc-module" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 6.0"
  project_id   = var.project_id # Replace this with your project ID
  network_name = "my-custom-mode-network"
  mtu          = 1460

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = "us-west1"
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = "us-west1"
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    },
    {
      subnet_name               = "subnet-03"
      subnet_ip                 = "10.10.30.0/24"
      subnet_region             = "us-west1"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
      subnet_flow_logs_filter   = "false"
    }
  ]
}
