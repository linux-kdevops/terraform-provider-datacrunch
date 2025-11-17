# DataCrunch Terraform Provider

The Terraform provider for DataCrunch enables the declarative management of resources in [DataCrunch](https://datacrunch.io).

[![Build Status](https://github.com/linux-kdevops/terraform-provider-datacrunch/workflows/CI/badge.svg)](https://github.com/linux-kdevops/terraform-provider-datacrunch/actions?query=workflow%3ACI)

## Fork Information

This is a fork of [squat/terraform-provider-datacrunch](https://github.com/squat/terraform-provider-datacrunch) maintained by the [kdevops project](https://github.com/linux-kdevops/kdevops) for Linux kernel development and testing workflows.

**Key enhancements in this fork:**

- **Robust instance lifecycle management**: Added async waiters for instance creation and deletion that poll until operations complete, preventing Terraform from proceeding before resources are fully provisioned or destroyed
- **Location code handling**: Fixed inconsistent result errors when DataCrunch provisions instances in different regions than requested
- **Speakeasy-free development**: Removed Speakeasy dependency from default build workflow - SDK generation only needed when API spec changes
- **Production-ready**: Battle-tested with kdevops GPU workflows requiring reliable provisioning of H100, A100, and other high-demand GPU instances

**Use cases:**
- Linux kernel development and testing on GPU instances
- Machine learning research requiring automated GPU infrastructure
- Workflows needing reliable provisioning despite capacity constraints

**Integration with kdevops**: This provider powers kdevops' region-aware tier-based GPU selection, automatically finding available capacity across all DataCrunch regions and falling back through GPU tiers to maximize provisioning success rates.

<!-- Start SDK Installation [installation] -->
## SDK Installation

To install this provider, copy and paste this code into your Terraform configuration. Then, run `terraform init`.

```hcl
terraform {
  required_providers {
    datacrunch = {
      source  = "linux-kdevops/datacrunch"
      version = "0.0.3"
    }
  }
}

provider "datacrunch" {
  # Configuration options
}
```

**Note**: This provider will be published to the Terraform Registry as `linux-kdevops/datacrunch`. Until then, you can use the local development installation method below.
<!-- End SDK Installation [installation] -->



<!-- Start SDK Example Usage [usage] -->
## SDK Example Usage

### Building the provider locally

For day-to-day development when the SDK is already generated (checked into git), you can build and install the provider without the Speakeasy dependency:

```sh
make install
```

This compiles the existing Go code and installs the binary to `~/.terraform.d/plugins/` for use with dev_overrides in `~/.terraformrc`.

**Note**: You only need `make generate` (which requires Speakeasy) when:
- The DataCrunch API OpenAPI spec has changed
- You need to regenerate the SDK to pick up new API features

For normal development (modifying provider logic, fixing bugs), just use `make install`.

### Testing the provider locally

Should you want to validate a change locally, the `--debug` flag allows you to execute the provider against a terraform instance locally.

This also allows for debuggers (e.g. delve) to be attached to the provider.

### Example

```sh
go run main.go --debug
# Copy the TF_REATTACH_PROVIDERS env var
# In a new terminal
cd examples/your-example
TF_REATTACH_PROVIDERS=... terraform init
TF_REATTACH_PROVIDERS=... terraform apply
```

### Creating a new release

This provider uses [GoReleaser](https://goreleaser.com) to create releases with all required artifacts for the Terraform/OpenTofu registries.

**Prerequisites:**
- GoReleaser installed (`wget -qO- https://github.com/goreleaser/goreleaser/releases/download/v2.5.1/goreleaser_Linux_x86_64.tar.gz | sudo tar xz -C /usr/local/bin goreleaser`)
- GitHub CLI authenticated (`gh auth login`)
- GPG key for signing (public key fingerprint: `E4053F8D0E7C4B9A0A20AB27DC553250F8FE7407`)

**Steps to release:**

1. **Commit any pending changes** (GoReleaser requires a clean git state):
   ```bash
   git add .
   git commit -m "Your changes"
   git push
   ```

2. **Create and push a git tag** for the version (e.g., v0.0.4):
   ```bash
   git tag -a v0.0.4 -m "Release v0.0.4 - description of changes"
   git push kdevops v0.0.4
   ```

3. **Cache your GPG passphrase** (to avoid timeout during signing):
   ```bash
   echo "test" | gpg --armor --detach-sign --local-user E4053F8D0E7C4B9A0A20AB27DC553250F8FE7407 --output /tmp/test.sig
   # Enter your GPG passphrase when prompted - it will be cached for ~2 hours
   ```

4. **Run GoReleaser** to build and publish the release:
   ```bash
   export GPG_FINGERPRINT="E4053F8D0E7C4B9A0A20AB27DC553250F8FE7407"
   GITHUB_TOKEN=$(gh auth token) goreleaser release --clean
   ```

This will:
- Build binaries for all platforms (Linux, macOS, Windows, FreeBSD × amd64, 386, arm, arm64)
- Create `.zip` archives for each platform
- Generate `terraform-provider-datacrunch_X.Y.Z_SHA256SUMS` (required by registries)
- GPG sign the checksums → `terraform-provider-datacrunch_X.Y.Z_SHA256SUMS.sig`
- Upload all artifacts to GitHub Releases
- Enable the OpenTofu/Terraform registry bots to detect and index the provider

**Note:** If you get a GPG timeout error, increase the cache timeout:
```bash
echo "default-cache-ttl 28800" >> ~/.gnupg/gpg-agent.conf
echo "max-cache-ttl 28800" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

<!-- End SDK Example Usage [usage] -->



<!-- Start Available Resources and Operations [operations] -->
## Available Resources and Operations

### Resources

- `datacrunch_instance` - Manage DataCrunch GPU instances
- `datacrunch_ssh_key` - Manage SSH keys for instance access

### Data Sources

- `datacrunch_instance_types` - Query available instance types with CPU, GPU, memory, and pricing information
- `datacrunch_images` - Query available OS images
- `datacrunch_locations` - Query available datacenter locations

<!-- End Available Resources and Operations [operations] -->

<!-- Placeholder for Future Speakeasy SDK Sections -->

Terraform allows you to use local provider builds by setting a `dev_overrides` block in a configuration file called `.terraformrc`. This block overrides all other configured installation methods.

Terraform searches for the `.terraformrc` file in your home directory and applies any configuration settings you set.

```
provider_installation {

  dev_overrides {
      "linux-kdevops/datacrunch" = "/home/your-user/.terraform.d/plugins/registry.terraform.io/linux-kdevops/datacrunch/0.0.3/linux_amd64"
  }

  # For all other providers, install them directly from their origin provider
  # registries as normal. If you omit this, Terraform will _only_ use
  # the dev_overrides block, and so no other providers will be available.
  direct {}
}
```

The `make install` target installs the provider to `~/.terraform.d/plugins/registry.terraform.io/linux-kdevops/datacrunch/0.0.3/linux_amd64/` by default.

### Generation

This project is generated using [Speakeasy](https://github.com/speakeasy-api/speakeasy).
