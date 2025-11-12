# DataCrunch Terraform Provider

The Terraform provider for DataCrunch enables the declarative management of resources in [DataCrunch](https://datacrunch.io).

[![Build Status](https://github.com/squat/terraform-provider-datacrunch/workflows/CI/badge.svg)](https://github.com/squat/terraform-provider-datacrunch/actions?query=workflow%3ACI)

<!-- Start SDK Installation [installation] -->
## SDK Installation

To install this provider, copy and paste this code into your Terraform configuration. Then, run `terraform init`.

```hcl
terraform {
  required_providers {
    datacrunch = {
      source  = "squat/datacrunch"
      version = "0.0.2"
    }
  }
}

provider "datacrunch" {
  # Configuration options
}
```
<!-- End SDK Installation [installation] -->



<!-- Start SDK Example Usage [usage] -->
## SDK Example Usage

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
      "squat/datacrunch" = "<PATH>"
  }

  # For all other providers, install them directly from their origin provider
  # registries as normal. If you omit this, Terraform will _only_ use
  # the dev_overrides block, and so no other providers will be available.
  direct {}
}
```

Your `<PATH>` may vary depending on how your Go environment variables are configured. Execute `go env GOBIN` to set it, then set the `<PATH>` to the value returned. If nothing is returned, set it to the default location, `$HOME/go/bin`.

### Generation

This project is generated using [Speakeasy](https://github.com/speakeasy-api/speakeasy).
