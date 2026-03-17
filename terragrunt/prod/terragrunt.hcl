# Production environment configuration
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  environment = "prod"

  splunk_admin_password = get_env("SPLUNK_ADMIN_PASSWORD", "CHANGE_ME_USE_ENV_VAR")
}
