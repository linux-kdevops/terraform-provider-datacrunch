# Development Guide

## Building the Provider

Build the provider binary:

```bash
go build -o terraform-provider-datacrunch
```

## Local Installation for Testing

To use the locally built provider with Terraform/OpenTofu, you need to set up provider development overrides.

### Step 1: Create Provider Directory Structure

```bash
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/squat/datacrunch/0.0.2/linux_amd64/
```

Note: Adjust `linux_amd64` to match your platform (e.g., `darwin_amd64` for macOS, `darwin_arm64` for M1/M2 Macs).

### Step 2: Copy the Binary

```bash
cp terraform-provider-datacrunch ~/.terraform.d/plugins/registry.terraform.io/squat/datacrunch/0.0.2/linux_amd64/terraform-provider-datacrunch_v0.0.2
```

### Step 3: Configure Development Overrides

Create or edit `~/.terraformrc` with the following content:

```hcl
provider_installation {
  dev_overrides {
    "squat/datacrunch" = "/home/YOUR_USERNAME/.terraform.d/plugins/registry.terraform.io/squat/datacrunch/0.0.2/linux_amd64"
  }
  direct {}
}
```

Replace `YOUR_USERNAME` with your actual username, or use the full path from Step 1.

### Step 4: Test the Provider

Create a test configuration:

```hcl
terraform {
  required_providers {
    datacrunch = {
      source = "squat/datacrunch"
    }
  }
}

provider "datacrunch" {
  bearer     = "your-api-token"
  server_url = "https://api.datacrunch.io/v1"
}

data "datacrunch_locations" "available" {}

output "locations" {
  value = data.datacrunch_locations.available
}
```

Run `terraform plan` (skip `terraform init` when using dev overrides):

```bash
terraform plan
```

You should see output indicating the provider loaded successfully and queried the DataCrunch API.

## Testing Resources

### SSH Key Management

```hcl
resource "datacrunch_ssh_key" "example" {
  name       = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

### Instance Deployment

```hcl
resource "datacrunch_instance" "example" {
  hostname      = "test-instance"
  description   = "Test GPU instance"
  image         = "ubuntu-22.04-cuda-12.0"
  instance_type = "1V100.6V"
  location_code = "FIN-01"
  ssh_key_ids   = [datacrunch_ssh_key.example.id]
}

output "instance_ip" {
  value = datacrunch_instance.example.ip
}
```

## Data Source Examples

### Query Available Instance Types

```hcl
data "datacrunch_instance_types" "all" {}

output "gpu_instances" {
  value = [
    for t in data.datacrunch_instance_types.all.instance_types :
    {
      type  = t.instance_type
      gpu   = t.gpu
      price = t.price_per_hour
    }
  ]
}
```

### Query Available Images

```hcl
data "datacrunch_images" "all" {}

output "ubuntu_images" {
  value = [
    for img in data.datacrunch_images.all.images :
    img if can(regex("ubuntu", lower(img.name)))
  ]
}
```

### Query Available Locations

```hcl
data "datacrunch_locations" "all" {}

output "locations" {
  value = data.datacrunch_locations.all.locations
}
```

## Important Notes

- When using development overrides, you should **skip** `terraform init` as it may error unexpectedly
- The provider uses OAuth2 bearer token authentication
- All data sources query the live DataCrunch API
- Instance creation is a two-step process: deploy returns only ID, then we fetch full details
- SSH keys must be added before deploying instances that reference them

## Debugging

To enable detailed logging:

```bash
export TF_LOG=DEBUG
terraform plan
```

To run the provider in debug mode with a debugger:

```bash
go run main.go --debug
# Copy the TF_REATTACH_PROVIDERS output
# In a new terminal:
TF_REATTACH_PROVIDERS='...' terraform plan
```
