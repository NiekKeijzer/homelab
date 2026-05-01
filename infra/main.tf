locals {
  _pkrvars_files = fileset("${path.module}/../packer-templates", "*.pkrvars.hcl")

  _pkrvars_content = {
    for f in local._pkrvars_files : trimsuffix(f, ".pkrvars.hcl") => file("${path.module}/../packer-templates/${f}")
  }

  # Sync the VM IDs and tags from the Packer variable files to avoid hardcoding them in Terraform
  vm_templates = {
    for name, content in local._pkrvars_content : name => {
      id   = split("\"", regex("vm_id\\s*=\\s*\"\\d+\"", content))[1]
      tags = [for t in regexall("\"[a-z][a-z0-9-]*\"", regex("vm_tags[^\n]*", content)) : trim(t, "\"") if !contains(["template", "packer"], trim(t, "\""))]
    }
  }

  provision = {
    user        = var.provision_user
    public_keys = var.provision_ssh_public_keys
  }
}
