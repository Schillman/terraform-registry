# Terraform Registry

This is my central repository for storing a collection of Terraform modules.

## Using Modules

You can easily reference modules from this repository by using the `source` and `version` arguments in your Terraform configuration.

```hcl
module "vending_machine" {
  source = "github.com/Schillman/terraform-registry//modules/terraform-azurerm-subscription?ref=v1.0"

  # Your module configuration here
}
```

Make sure to specify the correct `source` URL and version to retrieve the desired module.

## Adding Modules

When adding new modules to this repository, follow these guidelines:

- Place modules in the `modules/` directory.
- Each and every module should include a corresponding tests and/or examples in the `tests/` and/or `examples/` directories.
- Adhere to Terraform's standard naming conventions for modules, which follow the format: `terraform-${provider}-${module_name`, for example, `terraform-docker-container`.

Contributions and improvements to the Terraform Registry are welcome. Feel free to open issues or submit pull requests to enhance the collection of Terraform modules.
