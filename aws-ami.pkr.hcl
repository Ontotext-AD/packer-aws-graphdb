# Packer configuration for creating an Amazon Machine Image (AMI) for GraphDB.
packer {
  # Required Packer plugins and their versions.
  required_plugins {
    amazon = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

######## Variables ######## 

# Defines variables and default values.
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

variable "build_instance_type" {
  description = "EC2 instance type to use for building the AMI"
  type        = string
  default     = "m5.large"
}

variable "build_vpc_id" {
  description = "VPC ID where the AMI will be built"
  type        = string
}

variable "build_subnet_id" {
  description = "Subnet ID where the AMI will be built"
  type        = string
}

# Defines a local variable to generate a timestamp for AMI naming.
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# Defines the source configuration for the Amazon EBS builder.
source "amazon-ebs" "ubuntu" {
  ami_name      = "ami-ontotext-graphdb-${var.gdb_version}-${local.timestamp}"
  instance_type = "${var.build_instance_type}"
  vpc_id        = "${var.build_vpc_id}"
  subnet_id     = "${var.build_subnet_id}"
  ami_regions   = "${var.build_aws_regions}"

  # Specify the source AMI to use as a base.
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # AWS account ID of the owner.
  }

  # SSH configuration for connecting to the instance.
  ssh_username                = "ubuntu"
  associate_public_ip_address = true
  ssh_interface               = "public_ip"
}

build {
  name = "graphdb-ami"
  # Specify the sources for the build, including the Amazon EBS source defined above.
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  # Provisioning steps
  provisioner "file" {
    sources     = ["./files/graphdb.service", "./files/graphdb-cluster-proxy.service", "./files/graphdb.properties", "./files/install_graphdb.sh"]
    destination = "/tmp/"
  }

  provisioner "shell" {
    # Set an environment variable for GraphDB version.
    environment_vars = [
      "GRAPHDB_VERSION=${var.gdb_version}",
    ]
    # Execute the GraphDB installation script.
    inline = ["sudo -E bash /tmp/install_graphdb.sh"]
  }
}
