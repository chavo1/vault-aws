module "vault-terraform" {
  source = "../"

  access_key    = var.access_key
  secret_key    = var.secret_key
  region        = var.region
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet        = var.subnet
  vault_count   = var.vault_count
  ami           = var.ami
}

output "public_dns_vault" {
  value = "${module.vault-terraform.public_dns_vault}"
}
