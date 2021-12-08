

########################################################################################################################
### Variables
########################################################################################################################

variable compartment_root {}
variable tenancy_ocid {}
variable compartment_ocid {}
variable region {}
variable current_user_ocid {}

variable "project_name" {}
variable "environment" {}

variable "compartment_description" {}
variable "compartment_name" {}

variable "admin_password" {}

variable resource_tags {
    type = map
    default ={}
}

variable "slackname" {}
variable "email" {}
variable "lifecycle_type" {}
variable "purpose" {}

variable "enable_dataguard" {
    type = bool
    default = false
}
 
 locals {
    required_tags ={
        project = var.project_name,
        environment = var.environment,
        # launch-id = uuidv5("oid",timestamp()),
        slack =  var.slackname
        "email" = var.email,
        "ops"   = "terraform",
        "Purpose"= var.purpose,
        "Lifecycle" = var.lifecycle_type
        }
    tags = merge(var.resource_tags, local.required_tags)
}

/**/
########################################################################################################################
### Data Objects
########################################################################################################################

data "oci_identity_regions" "regions" {
}

data "oci_identity_tenancy" "root" {
    #Required
    tenancy_id = var.compartment_root
}


data "oci_identity_compartments" "govmod" {
    #Required
    compartment_id = data.oci_identity_tenancy.root.tenancy_id
    name = "GovMod"
    # state = var.compartment_state
}

data "oci_identity_compartment" "root" {
    #Required
    id = var.compartment_root
}

data "oci_database_autonomous_databases" "databases" {
    #Required
    compartment_id = oci_identity_compartment.demo.id

    #Optional
    # autonomous_container_database_id = oci_database_autonomous_container_database.test_autonomous_container_database.id
    # db_version = var.autonomous_database_db_version
    # db_workload = var.autonomous_database_db_workload
    # display_name = var.autonomous_database_display_name
    # infrastructure_type = var.autonomous_database_infrastructure_type
    # is_data_guard_enabled = var.autonomous_database_is_data_guard_enabled
    # is_free_tier = var.autonomous_database_is_free_tier
    # is_refreshable_clone = var.autonomous_database_is_refreshable_clone
    state = "AVAILABLE"
}

/**/
########################################################################################################################
### Resources
########################################################################################################################
data "http" "myip6" {
  url = "https://ident.me"
}


data "http" "myip4" {
  url = "https://api.ipify.org"
}


resource "oci_identity_compartment" "demo" {
    #Required
    compartment_id = data.oci_identity_compartments.govmod.compartments.0.id
    description = var.compartment_description
    name = var.compartment_name

    #Optional
    enable_delete = true
    freeform_tags = local.tags
}

/**/
#######################################
### Autonomous Variables
#######################################


variable "databases" {
  description = "The number of databases to create, by default it's one of each type."
  type    = map(object({
      dbtype  = string
  }))
  default = {
      1 = {
            dbtype = "OLTP"
        }
      2 = {
            dbtype = "APEX"
        }
      3 = {
            dbtype = "ADJ"
        }
      4 = {
            dbtype = "DW"
        }                     
     #  ["OLTP", "DW", "AJD", "APEX"]
  }
}

variable "license_model" {
  type    = map(string)
    default = {
        "AJD" = "LICENSE_INCLUDED"
        "APEX" = "LICENSE_INCLUDED"
    }
}


resource "oci_database_autonomous_database" "demo" {
  #for_each = toset(var.databases)
  for_each = var.databases
    compartment_id             = oci_identity_compartment.demo.id
    cpu_core_count             = 1
    data_safe_status           = "NOT_REGISTERED"
    data_storage_size_in_tbs   = 2
    db_name                    = "${format("db%02s", each.key)}"
    db_version                 = "19c"
    db_workload                = each.value.dbtype
    # OLTP - indicates an Autonomous Transaction Processing database, 
    # DW - indicates an Autonomous Data Warehouse database
    # AJD - indicates an Autonomous JSON Database
    # APEX - indicates an Autonomous Database with the Oracle APEX Application 
    display_name               = "${format("db%02s", each.key)}"
    freeform_tags              = local.tags
    is_auto_scaling_enabled    = true
    is_data_guard_enabled      = var.enable_dataguard
    is_dedicated               = false
    is_free_tier               = false
    # kms_key_id                 = "ORACLE_MANAGED_KEY"
    #license_model              = "BRING_YOUR_OWN_LICENSE"
    license_model               = lookup(var.license_model, each.value.dbtype, "BRING_YOUR_OWN_LICENSE")
    nsg_ids                    = []
    open_mode                  = "READ_WRITE"
    operations_insights_status = "NOT_ENABLED"
    permission_level           = "UNRESTRICTED"
    standby_whitelisted_ips    = []
    state                      = "AVAILABLE"
    whitelisted_ips            = [
        data.http.myip4.body, "0.0.0.0/0"
    ]
    admin_password = var.admin_password
    timeouts {}

    depends_on = [oci_identity_compartment.demo]
}


########################################################################################################################
### Data Safe
### Comment Out until after first create
#########################################

/*
resource "oci_data_safe_target_database" "db" {
  compartment_id = oci_identity_compartment.demo.id
  for_each = {for db in data.oci_database_autonomous_databases.databases.autonomous_databases : db.id => db}
  #credentials = <<Optional value not found in discovery>>data.oci_database_autonomous_databases.databases.autonomous_databases.*.id
  database_details {
    autonomous_database_id = each.value.id
    #db_system_id = <<Optional value not found in discovery>>
    # [AUTONOMOUS_DATABASE DATABASE_CLOUD_SERVICE INSTALLED_DATABASE]
    database_type = "AUTONOMOUS_DATABASE"
    infrastructure_type = "ORACLE_CLOUD"
    #instance_id = <<Optional value not found in discovery>>
    #ip_addresses = <<Optional value not found in discovery>>
    #listener_port = <<Optional value not found in discovery>>
    #service_name = <<Optional value not found in discovery>>
    #vm_cluster_id = <<Optional value not found in discovery>>
  }
  #description = <<Optional value not found in discovery>>
  freeform_tags = local.tags
  #tls_config = <<Optional value not found in discovery>>
  depends_on = [oci_database_autonomous_database.demo]
  timeouts {
    create = "60m"
    delete = "2h"
    }
}

/**/

########################################################################################################################
### Autonomous Backups - Comment Out until after first create.
########################################################################################################################
/*
data "oci_database_autonomous_database_backups" "backups" {
     compartment_id = oci_identity_compartment.demo.id

     depends_on = [oci_database_autonomous_database.demo]
}

resource "oci_database_autonomous_database_backup" "backup" {
    #Required
    for_each = {for backup in data.oci_database_autonomous_database_backups.backups.autonomous_database_backups : backup.id => backup}
    autonomous_database_id = each.value.autonomous_database_id
    display_name = each.key

    depends_on = [data.oci_database_autonomous_database_backups.backups]
}

output db_backups {
  value = oci_database_autonomous_database_backup.backup
}

/**/
########################################################################################################################
### Outputs
########################################################################################################################

output "GovMod_Base_Compartment_ID" {
    value = data.oci_identity_compartments.govmod.compartments.0.id
}

output "tenancy_name" {
   value = data.oci_identity_tenancy.root.name
}

output tenancy_root_compartment_id {
    value = data.oci_identity_compartment.root.id
}

output oci_identity_compartment_demo_id {
    value = oci_identity_compartment.demo.id
}

output Deployed_To_Compartment_Name {
    value = "Databases are deployed to ${oci_identity_compartment.demo.name} Compartment"
}



###############################
### DB Information
################################

output "database_ids" {
  value = {
    for k, v in oci_database_autonomous_database.demo : k => v.id
  }
}

output "database_connection_URLs" {
  value = {
    for k, v in oci_database_autonomous_database.demo : k => v.connection_urls
  }
}

output "data_all_dbids" {
  value = {
    for k, v in data.oci_database_autonomous_databases.databases.autonomous_databases: k => v.id
  }
}

output "ds" {
  value = {
    for k, v in data.oci_database_autonomous_databases.databases.autonomous_databases: k => k
  }
}

/*
output "database_connection_strings" {
  value = {
    for k, v in oci_database_autonomous_database.demo : k => v.connection_strings
  }
}


   
/**/