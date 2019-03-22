public_dns_vault = attribute(
  "public_dns_clients",
  description: "vault dns"
)

  describe http("https://#{public_dns_vault}:8200/ui/vault/unseal") do
    its('status') { should cmp 200 }
  end