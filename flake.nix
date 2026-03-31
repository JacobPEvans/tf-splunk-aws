# Terragrunt/OpenTofu Development Shell
#
# Complete IaC environment with Terragrunt, OpenTofu, security scanners,
# and AWS integration.
#
# Usage:
#   nix develop
#   # or with direnv: cd into repo → direnv allow (auto-activates)

{
  description = "Terragrunt/OpenTofu infrastructure development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
            };
          }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs }:
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # === Infrastructure as Code ===
              # terraform omitted: this repo uses OpenTofu (tofu), not Terraform
              terragrunt
              opentofu
              terraform-docs
              tflint

              # === Security & Compliance ===
              tfsec
              trivy

              # === Cloud & Development ===
              awscli2
              aws-vault
              git
              python3

              # === Utilities ===
              jq
              yq

              # === Dev Tooling ===
              pre-commit
            ];

            shellHook = ''
              if [ -z "''${DIRENV_IN_ENVRC:-}" ]; then
                echo "═══════════════════════════════════════════════════════════════"
                echo "Terragrunt/OpenTofu Infrastructure as Code Environment"
                echo "═══════════════════════════════════════════════════════════════"
                echo ""
                echo "Infrastructure as Code:"
                echo "  - terragrunt: $(terragrunt --version 2>/dev/null | cut -d' ' -f3)"
                echo "  - opentofu: $(tofu version 2>/dev/null | head -1)"
                echo ""
                echo "Security & Compliance:"
                echo "  - tfsec: $(tfsec --version 2>/dev/null)"
                echo ""
                echo "Cloud:"
                echo "  - aws-cli: $(aws --version 2>/dev/null)"
                echo ""
                echo "Getting Started:"
                echo "  1. Setup pre-commit: pre-commit install"
                echo "  2. Plan (requires aws-vault + Doppler):"
                echo "     aws-vault exec tf-splunk-aws -- doppler run -- terragrunt plan"
                echo ""
              fi
            '';
          };
        }
      );
    };
}
