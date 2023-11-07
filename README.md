# terraform-registry
Centralized Repository for Terraform Modules  This repository serves as a central hub for storing a collection of reusable Terraform modules.

## Using modules

Refer to modules in this repository with the `source` argument along with the `version` argument.
```hcl
module "vending_machine" {
  source = "github.com/Schillman/terraform-registry//modules/terraform-azurerm-subscription?ref=v1.0"

  ...
}
```
## Adding modules

Modules belong to the `modules/` directory, with a corresponding test or example in the
`tests/` and/or `example/` directory. Modules follow standard naming conventions from Terraform,
which is `terraform-${provider}-${module_name}`, e.g. `terraform-docker-container`.
