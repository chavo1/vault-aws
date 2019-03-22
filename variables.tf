variable "access_key" {}
variable "secret_key" {}
variable "subnet" {}
variable "instance_type" {}
variable "key_name" {}
variable "vault_count" {}

variable "ami" {
  default = "ami-04ddb558799a3dbd6"
}

variable "region" {
  default = "us-east-1"
}
