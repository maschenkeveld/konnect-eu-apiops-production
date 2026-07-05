variable "KPAT" {
  type        = string
  default     = ""
  description = "Konnect Personal Access Token. Supply via TF_VAR_KPAT (see export-secrets.sh)."
  sensitive   = true
}

variable "konnect_region" {
  type    = string
  default = "eu"
}

variable "HCV_ROOT_TOKEN" {
  type        = string
  default     = ""
  description = "HashiCorp Vault token. Supply via TF_VAR_HCV_ROOT_TOKEN (see export-secrets.sh)."
  sensitive   = true
}

variable "write_to_openbao" {
  type        = bool
  default     = true
  description = "Write connection/portal details to OpenBao."
}

variable "write_to_file" {
  type        = bool
  default     = true
  description = "Write connection/portal details to a local JSON file."
}

variable "local_output_file" {
  type        = string
  default     = "connection-details.json"
  description = "Filename (relative to the stack) for the local details file."
}
