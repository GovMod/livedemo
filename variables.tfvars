# compartment_root = "ocid1.tenancy.oc1..set_this_using_env_variable_TF_VAR_compartment_ocid"

region ="us-ashburn-1"

project_name = "DevOpsTesting"
environment = "testbuild"

compartment_description = "test compartment - terraform code testing"
compartment_name = "RapidApplication"

# databases = ["OLTP", "DW", "AJD", "APEX"]
# number is the index key and must be unique or duplicate is ignored
databases = {
    1 = {dbtype = "OLTP"}
   # 2 = {dbtype = "DW"}
   # 3 = {dbtype = "APEX"}
   # 4 = {dbtype = "AJD"}                         
  }

# Suggest setting as ENV or passing in as secret
admin_password = "Manager422021#"

slackname = "govmod"
email = "email@oracle.com"
lifecycle_type = "Ephemeral"

# Demo, Test, POC"
purpose = "test"

# Must be set to false on create
enable_dataguard = false


# Comment These out when running from resource manager
compartment_ocid = "Automated via Resource Manager"
current_user_ocid = "Automated via Resource Manager"
tenancy_ocid = "Automated via Resource Manager"


