# Local variable to generate a timestamp for unique AMI naming.
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu-x86-64" {
  ami_name      = "ami-ontotext-graphdb-${var.gdb_version}-x86-64-${local.timestamp}"
  instance_type = "${var.build_instance_type_x86-64}"
  vpc_id        = "${var.build_vpc_id}"
  subnet_id     = "${var.build_subnet_id}"
  ami_regions   = "${var.build_aws_regions}"
  ami_groups    = "${var.ami_groups}"
  encrypt_boot  = false
  ebs_optimized = true

  tags = {
    GDB_Version      = "${var.gdb_version}"
    CPU_Architecture = "x86-64"
    Build_Timestamp  = "${local.timestamp}"
  }

  source_ami_filter {
    filters = {
      name                = "${var.source_ami_name_filter_x86-64}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username                = "ubuntu"
  associate_public_ip_address = true
  ssh_interface               = "session_manager"
  communicator                = "ssh"
  iam_instance_profile        = "${var.iam_instance_profile}"
  ssh_clear_authorized_keys   = true
}

source "amazon-ebs" "ubuntu-arm64" {
  ami_name      = "ami-ontotext-graphdb-${var.gdb_version}-arm64-${local.timestamp}"
  instance_type = "${var.build_instance_type_arm64}"
  vpc_id        = "${var.build_vpc_id}"
  subnet_id     = "${var.build_subnet_id}"
  ami_regions   = "${var.build_aws_regions}"
  ami_groups    = "${var.ami_groups}"
  encrypt_boot  = false
  ebs_optimized = true

  tags = {
    GDB_Version      = "${var.gdb_version}"
    CPU_Architecture = "arm64"
    Build_Timestamp  = "${local.timestamp}"
  }

  source_ami_filter {
    filters = {
      name                = "${var.source_ami_name_filter_arm64}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username                = "ubuntu"
  associate_public_ip_address = true
  ssh_interface               = "session_manager"
  communicator                = "ssh"
  iam_instance_profile        = "${var.iam_instance_profile}"
  ssh_clear_authorized_keys   = true
}
