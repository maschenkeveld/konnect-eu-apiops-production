# konnect-eu-apiops-production

Terraform for the **production** APIOps environment on Kong Konnect.

## What it provisions
- Gateway control plane `apiops-production` + data-plane client certificate
- **Production portal** `apiops-production-portal` (`kong/konnect-beta`) + branding (`konnect_portal_customization`)
- **connection-details** — control-plane endpoints + `portal_id` + `portal_default_domain`, written to
  **OpenBao** and/or a **local file** (see toggles)

## Prerequisites
- `terraform`, network access to `eu.api.konghq.com` (and OpenBao if `write_to_openbao=true`)
- Secrets via env: set `TF_VAR_KPAT` (Konnect PAT) and `TF_VAR_HCV_ROOT_TOKEN` (OpenBao token).
  **Never hardcode these in `*.tf`.**
- Root CA cert present at `../../../ansible/roles/tls/files/root-ca-cert.pem`

## Usage
```bash
export TF_VAR_KPAT=kpat_...  TF_VAR_HCV_ROOT_TOKEN=...
terraform init -upgrade   # -upgrade needed after provider changes
terraform plan
terraform apply
```

## Toggles (variables)
| Variable | Default | Effect |
|---|---|---|
| `write_to_openbao` | `true` | write connection-details to OpenBao `kv/konnect/konnect-eu-apiops-production/connection-details` |
| `write_to_file` | `true` | write the same JSON to `connection-details.json` (git-ignored) |
| `local_output_file` | `connection-details.json` | local filename |

## Outputs & consumers
- `terraform output`: `control_plane_endpoint`, `telemetry_endpoint`, `portal_id`, `portal_default_domain`
- **ESO** (gitops `konnect-data-plane`) reads the OpenBao `connection-details` to configure the data plane
- **`portal_id` → set it as the APIOps `KONNECT_PORTAL_ID` GitHub variable** — the release pipeline
  publishes APIs to this portal
