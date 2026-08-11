terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "2.8.1"
    }

    # The "new" Konnect portals live in the beta provider.
    konnect-beta = {
      source  = "kong/konnect-beta"
      version = "0.11.2"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "3.0.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

provider "konnect" {
  personal_access_token = var.KPAT
  server_url            = "https://eu.api.konghq.com"
}

provider "konnect-beta" {
  personal_access_token = var.KPAT
  server_url            = "https://eu.api.konghq.com"
}

# OpenBao is API-compatible with Vault, so the hashicorp/vault provider is used against it.
provider "vault" {
  address = "https://openbao.shared.pve-home.schenkeveld.io"
  token   = var.HCV_ROOT_TOKEN
}

resource "konnect_gateway_control_plane" "apiops_production_gateway_control_plane" {
  name          = "apiops-production"
  cluster_type  = "CLUSTER_TYPE_CONTROL_PLANE"
  cloud_gateway = false
  auth_type     = "pki_client_certs"
  proxy_urls    = []
}

resource "konnect_gateway_data_plane_client_certificate" "apiops_production_gatewaydataplaneclientcertificate" {
  cert             = file("../../../ansible/roles/tls/files/root-ca-cert.pem")
  control_plane_id = konnect_gateway_control_plane.apiops_production_gateway_control_plane.id
}

output "control_plane_full_output" {
  value = konnect_gateway_control_plane.apiops_production_gateway_control_plane
}

output "control_plane_endpoint" {
  value = konnect_gateway_control_plane.apiops_production_gateway_control_plane.config.control_plane_endpoint
}

output "telemetry_endpoint" {
  value = konnect_gateway_control_plane.apiops_production_gateway_control_plane.config.telemetry_endpoint
}

# Single source for the details, written to OpenBao and/or a local file below.
locals {
  connection_details = {
    control_plane          = replace(konnect_gateway_control_plane.apiops_production_gateway_control_plane.config.control_plane_endpoint, "https://", "")
    telemetry              = replace(konnect_gateway_control_plane.apiops_production_gateway_control_plane.config.telemetry_endpoint, "https://", "")
    control_plane_endpoint = format("%s:443", replace(konnect_gateway_control_plane.apiops_production_gateway_control_plane.config.control_plane_endpoint, "https://", ""))
    telemetry_endpoint     = format("%s:443", replace(konnect_gateway_control_plane.apiops_production_gateway_control_plane.config.telemetry_endpoint, "https://", ""))

    # Portal coordinates — consumed by the APIOps pipeline (optional OpenBao read) and available to ESO.
    portal_id             = konnect_portal.apiops_production_portal.id
    portal_default_domain = konnect_portal.apiops_production_portal.default_domain
  }
}

# Write to OpenBao (for ESO + optional pipeline read). Toggle with var.write_to_openbao.
resource "vault_generic_secret" "konnect_endpoints" {
  count     = var.write_to_openbao ? 1 : 0
  path      = "kv/konnect/konnect-eu-apiops-production/connection-details"
  data_json = jsonencode(local.connection_details)
}

# Write the same details to a local JSON file. Toggle with var.write_to_file.
resource "local_file" "connection_details" {
  count    = var.write_to_file ? 1 : 0
  filename = "${path.module}/${var.local_output_file}"
  content  = jsonencode(local.connection_details)
}

# --- Production Portal (new / beta portals) --------------------------------
# The production Dev Portal. Grab its ID with `terraform output portal_id` and store it as the
# APIOps KONNECT_PORTAL_ID GitHub variable (the release pipeline publishes here).
# Schema is for kong/konnect-beta v0.11.2 — re-check with `terraform plan` if bumped.
resource "konnect_portal" "apiops_production_portal" {
  provider = konnect-beta

  name         = "apiops-production-portal"
  display_name = "APIOps Production Portal"
  description  = "Production portal for APIs on the production control plane"

  authentication_enabled    = false
  auto_approve_applications = false
  auto_approve_developers   = false
  default_api_visibility    = "public"
  default_page_visibility   = "public"
  rbac_enabled              = false

  labels = {
    managed_by = "platformops"
    env        = "production"
  }
}

resource "konnect_portal_customization" "apiops_production_portal" {
  provider  = konnect-beta
  portal_id = konnect_portal.apiops_production_portal.id

  theme = {
    mode = "light"
    colors = {
      primary = "#0A1F44" # Navy — production (distinct from dev)
    }
  }

  spec_renderer = {
    allow_custom_server_urls = true
    hide_deprecated          = false
    hide_internal            = false
    infinite_scroll          = false
    show_schemas             = true
    try_it_insomnia          = false
    try_it_ui                = true
  }
}

resource "konnect_portal_page" "apiops_production_portal_overview" {
  provider  = konnect-beta
  portal_id = konnect_portal.apiops_production_portal.id

  slug       = "overview"
  title      = "Overview"
  status     = "published"
  visibility = "public"

  content = <<-EOT
    # APIOps Developer Portal

    Welcome to the developer portal for APIs running on the production control
    plane. Browse the API Catalog to explore available APIs, view their specs,
    and register applications.
  EOT
}

output "portal_id" {
  value = konnect_portal.apiops_production_portal.id
}

output "portal_default_domain" {
  value = konnect_portal.apiops_production_portal.default_domain
}
