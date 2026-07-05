# AGENTS.md

Terraform stack for the **production** APIOps Konnect environment. See [README.md](README.md).

## Rules
- **Always `terraform plan` before `apply`** — this mutates live *production* Konnect (control plane, portal) and OpenBao.
- **Never commit** `TF_VAR_KPAT` / `TF_VAR_HCV_ROOT_TOKEN` values, `terraform.tfstate*`, or `connection-details.json` (git-ignored). Tokens come from env, never hardcoded in `*.tf`.
- Providers are pinned (`kong/konnect`, `kong/konnect-beta`, `hashicorp/vault`→OpenBao, `hashicorp/local`); run `terraform init -upgrade` after changing them.
- The portal uses `kong/konnect-beta` (the "new" portals). If you bump that provider, re-verify `konnect_portal*` attributes with `plan`.

## Shape
`main.tf` builds a `locals.connection_details` map (endpoints + portal id), then writes it to OpenBao (`write_to_openbao`) and/or a local file (`write_to_file`), both default `true`. This portal's `portal_id` is what the APIOps release pipeline publishes to — surface it as the `KONNECT_PORTAL_ID` variable.
