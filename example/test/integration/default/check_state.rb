describe command('terraform state list') do
  its('stdout') { should include "module.vault-terraform.aws_instance.vault" }
  its('stderr') { should include '' }
  its('exit_status') { should eq 0 }
end

