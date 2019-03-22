# This example contains a demo of [Vault](https://www.vaultproject.io/) in AWS over HTTPS

- Create terraform.tfvars file with needed credential and variables:
```
access_key = "< Your AWS Access_key >"
secret_key = "< Your AWS Secret_key >"
key_name = "id_rsa"
region = "us-east-1"
instance_type = "t2.micro"
subnet = "< VPC subnet ID >"
vault_count = 1
```
### We can start with deploying process
```
terraform init
terraform plan
terraform apply
```
### Do not forget to destroy the environment after the test
```
terraform destroy
```

### To test the module you will need Kitchen:

Kitchen is a RubyGem so please find how to install and setup Test Kitchen, check out the [Getting Started Guide](http://kitchen.ci/docs/getting-started/).
For more information about kitchen tests please check the next link:

https://kitchen.ci/docs/getting-started/running-test/

Than simply execute a following commands:
```
kitchen converge
kitchen verify
kitchen destroy
```
- Kitchen-Terraform tests are for 1 Vault server and should be as follow:

```
  Command: `terraform state list`
     ✔  stdout should include "module.vault-terraform.aws_instance.vault"
     ✔  stderr should include ""
     ✔  exit_status should eq 0

Test Summary: 3 successful, 0 failures, 0 skipped
```
