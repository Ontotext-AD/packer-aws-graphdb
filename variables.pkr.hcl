variable "gdb_version" {
  description = "GraphDB version to install and package"
  type        = string
  default     = "10.3.3"
}

variable "build_aws_regions" {
  description = "AWS regions where to publish the AMI"
  type        = list(string)
  default     = ["us-east-1"]
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
