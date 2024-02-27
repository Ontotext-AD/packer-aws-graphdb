locals {
  # Generates a timestamp for unique AMI naming.
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

data "amazon-ami" "ubuntu_x86_64" {
  filters = {
    name                = var.source_ami_name_filter_x86_64
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = var.source_ami_owners_x86_64
}

source "amazon-ebs" "ubuntu_x86_64" {
  skip_create_ami = var.skip_create_ami

  #
  # AMI configurations
  #
  ami_name        = "ami-ontotext-graphdb-${var.graphdb_version}-x86-64-${local.timestamp}"
  ami_description = "GraphDB v${var.graphdb_version} by Ontotext"

  ami_virtualization_type = "hvm"
  encrypt_boot            = false
  ebs_optimized           = true
  ena_support             = true

  ami_regions  = var.ami_regions
  ami_users    = var.ami_users
  ami_groups   = var.ami_groups
  ami_org_arns = var.ami_org_arns
  ami_ou_arns  = var.ami_ou_arns

  tags = merge({
    GraphDB_Version  = var.graphdb_version
    CPU_Architecture = "x86-64"
    Build_Timestamp  = local.timestamp
  }, var.ami_tags)

  #
  # Access configurations
  #
  access_key = var.access_key
  secret_key = var.secret_key

  shared_credentials_file = var.shared_credentials_file
  profile                 = var.shared_credentials_file_profile

  #
  # Build configurations
  #
  region    = var.build_region
  vpc_id    = var.build_vpc_id
  subnet_id = var.build_subnet_id

  instance_type        = var.build_instance_type_x86_64
  source_ami           = data.amazon-ami.ubuntu_x86_64.id
  iam_instance_profile = var.build_iam_instance_profile
  user_data_file       = var.user_data_file

  associate_public_ip_address               = var.build_assign_public_ip_address
  temporary_security_group_source_cidrs     = var.build_security_group_cidrs
  temporary_security_group_source_public_ip = var.build_security_group_source_public_ip

  run_tags = var.build_tags

  #
  # SSH / Session Manager
  #
  communicator              = "ssh"
  ssh_interface             = var.ssh_interface
  ssh_username              = "ubuntu"
  ssh_clear_authorized_keys = true
}

data "amazon-ami" "ubuntu_arm64" {
  filters = {
    name                = var.source_ami_name_filter_arm64
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = var.source_ami_owners_arm64
}

source "amazon-ebs" "ubuntu_arm64" {
  skip_create_ami = var.skip_create_ami

  #
  # AMI configurations
  #
  ami_name        = "ami-ontotext-graphdb-${var.graphdb_version}-arm64-${local.timestamp}"
  ami_description = "GraphDB v${var.graphdb_version} by Ontotext"

  ami_virtualization_type = "hvm"
  encrypt_boot            = false
  ebs_optimized           = true
  ena_support             = true

  ami_regions  = var.ami_regions
  ami_users    = var.ami_users
  ami_groups   = var.ami_groups
  ami_org_arns = var.ami_org_arns
  ami_ou_arns  = var.ami_ou_arns

  tags = merge({
    GraphDB_Version  = var.graphdb_version
    CPU_Architecture = "arm64"
    Build_Timestamp  = local.timestamp
  }, var.ami_tags)

  #
  # Access configurations
  #
  access_key = var.access_key
  secret_key = var.secret_key

  shared_credentials_file = var.shared_credentials_file
  profile                 = var.shared_credentials_file_profile

  #
  # Build configurations
  #
  region    = var.build_region
  vpc_id    = var.build_vpc_id
  subnet_id = var.build_subnet_id

  instance_type        = var.build_instance_type_arm64
  source_ami           = data.amazon-ami.ubuntu_arm64.id
  iam_instance_profile = var.build_iam_instance_profile
  user_data_file       = var.user_data_file

  associate_public_ip_address               = var.build_assign_public_ip_address
  temporary_security_group_source_cidrs     = var.build_security_group_cidrs
  temporary_security_group_source_public_ip = var.build_security_group_source_public_ip

  run_tags = var.build_tags

  #
  # SSH / Session Manager
  #
  communicator              = "ssh"
  ssh_interface             = var.ssh_interface
  ssh_username              = "ubuntu"
  ssh_clear_authorized_keys = true
}
