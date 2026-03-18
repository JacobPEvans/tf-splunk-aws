# Production environment configuration
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  environment = "prod"

  # Empty default intentionally fails the >= 8 char validation when env var is not set
  splunk_admin_password = get_env("SPLUNK_PASSWORD", "")
}
