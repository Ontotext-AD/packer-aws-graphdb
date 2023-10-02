# Packer configuration for creating an Amazon Machine Image (AMI) for GraphDB.

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "gdb_version" {
  description = "GraphDB version to install and package"
  type        = string
  default     = "10.3.3"
}

variable "build_aws_regions" {
  description = "AWS regions where to publish the AMI"
  type        = list(string)
  default     = ["eu-central-1"]
}

variable "build_instance_type_x86-64" {
  description = "EC2 instance type to use for building the x86-64 AMI"
  type        = string
  default     = "t3.small"
}

variable "build_instance_type_arm64" {
  description = "EC2 instance type to use for building the arm64 AMI"
  type        = string
  default     = "t4g.small"
}

variable "build_vpc_id" {
  description = "VPC ID where the AMI will be built"
  type        = string
}

variable "build_subnet_id" {
  description = "Subnet ID where the AMI will be built"
  type        = string
}

variable "source_ami_name_filter_arm64" {
  description = "Name filter for the source arm64 AMI image"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-arm64-server-*"
}

variable "source_ami_name_filter_x86-64" {
  description = "Name filter for the source x86-64 AMI image"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"
}

variable "ami_groups" {
  description = "Groups the AMI will be made available to"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile for the SSM"
  type        = string
}

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
}

source "amazon-ebs" "ubuntu-arm64" {
  ami_name      = "ami-ontotext-graphdb-${var.gdb_version}-arm64-${local.timestamp}"
  instance_type = "${var.build_instance_type_arm64}"
  vpc_id        = "${var.build_vpc_id}"
  subnet_id     = "${var.build_subnet_id}"
  ami_regions   = "${var.build_aws_regions}"
  ami_groups    = "${var.ami_groups}"

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
}

build {
  name = "graphdb-ami"
  sources = [
    "source.amazon-ebs.ubuntu-x86-64",
    "source.amazon-ebs.ubuntu-arm64"
  ]

  provisioner "file" {
    sources = [
      "./files/graphdb.service",
      "./files/graphdb-cluster-proxy.service",
      "./files/install_graphdb.sh"
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    environment_vars = [
      "GRAPHDB_VERSION=${var.gdb_version}",
    ]
    inline      = ["sudo -E bash /tmp/install_graphdb.sh"]
    max_retries = 3
  }
}
