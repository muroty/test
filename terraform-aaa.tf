##################################
# EDIT THE FOLLOWING PARAMETERS
#
# cloud_environment:            Cloud environment to be used.
#                               Default: public
#                               Possible values are public, usgovernment, german, and china
# tenant_id :                   Active directory's ID
#                               (Portal) Azure AD -> Properties -> Directory ID
#

variable "cloud_environment" {
    type = string
    default = "public"
}
variable "tenant_id" {
    type = string
    default = "7b56c7f7-6358-489b-96ea-aaaaaaaaaaaaaaaaa"
}

# By default setting the password to last for a year
variable "application_password_expiration" {
    type = string
    default = "8760h"
}


#######################################################
# Terraform Provider Setup
#######################################################

terraform {
    required_providers {
        azuread = {
            version = "=2.28.1"
        }
        random = {
            version = "=3.1.0"
        }
    }
}
provider "azuread" {
    tenant_id = var.tenant_id
    environment = var.cloud_environment
}

provider "random" {}


#######################################################
# Setting up an Application & Service Principal
#######################################################
resource "random_string" "unique_id" {
    length = 5
    min_lower = 5
    special = false
}

resource "azuread_application" "prisma_cloud_ad_app" {
    display_name               = "Prisma Cloud App ${random_string.unique_id.result}"

    required_resource_access {
        resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

        resource_access {
            id   = "df021288-bdef-4463-88db-" # User.Read.All
            type = "Role"
        }

        resource_access {
            id   = "246dd0d5-5bd0-4def-940b-" # Policy.Read.All
            type = "Role"
        }

        resource_access {
            id   = "5b567255-7703-4780-807c-" # Group.Read.All
            type = "Role"
        }

        resource_access {
            id   = "98830695-27a2-44f7-8c18-" # GroupMember.Read.All
            type = "Role"
        }

        resource_access {
            id   = "230c1aed-a721-4c5d-9cb4-" # Reports.Read.All
            type = "Role"
        }

        resource_access {
            id   = "7ab1d382-f21e-4acd-a863-" # Directory.Read.All
            type = "Role"
        }
        resource_access {
            id   = "dbb9058a-0e50-45d7-ae91-" # Domain.Read.All
            type = "Role"
        }
        resource_access {
            id   = "9a5d68dd-52b0-4cc2-bd40-" # Application.Read.All
            type = "Role"
        }
    }

    web {
        homepage_url  = "https://www.paloaltonetworks.com/prisma/cloud"
  }
}

resource "azuread_service_principal" "prisma_cloud_ad_sp" {
    application_id = azuread_application.prisma_cloud_ad_app.application_id
}

#######################################################
# Set Application Password
#######################################################
resource "random_password" "application_password" {
  length = 16
  special = true
}

resource "azuread_application_password" "password" {
    end_date_relative           = var.application_password_expiration
    application_object_id       = azuread_application.prisma_cloud_ad_app.object_id
}

output "a_active_directory_id" { value = var.tenant_id}
output "b_application_id"  { value = azuread_application.prisma_cloud_ad_app.application_id}
output "c_application_key" { value = nonsensitive(azuread_application_password.password.value)}
output "d_application_key_expiration" { value = azuread_application_password.password.end_date}
output "e_service_principal_object_id" { value = azuread_service_principal.prisma_cloud_ad_sp.id }
output "f_consent_link" { value = "https://portal.azure.com/?quickstart=true#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/${azuread_application.prisma_cloud_ad_app.application_id}/isMSAApp/"}