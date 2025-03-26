#####################
# GraphDB variables #
#####################

variable "graphdb_version" {
  description = "GraphDB version to install and package as an AMI"
  type        = string
  default     = "10.6.3"
}

####################
# Access variables #
####################

variable "access_key" {
  description = "Access key used to communicate with AWS"
  type        = string
  default     = null
}

variable "secret_key" {
  description = "Secret key used to communicate with AWS."
  type        = string
  default     = null
}

variable "shared_credentials_file" {
  description = "Path to a credentials file to load credentials from"
  type        = string
  default     = null
}

variable "shared_credentials_file_profile" {
  description = "Profile to use in the shared credentials file for AWS"
  type        = string
  default     = null
}

########################
# Source AMI variables #
########################

variable "source_ami_name_filter_x86_64" {
  description = "Name filter for the source x86-64 AMI image"
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-*-24.04-amd64-server-*"
}

variable "source_ami_owners_x86_64" {
  description = "Owners of the source AMI image for x86-64"
  type        = list(string)
  default     = ["099720109477"]
}

variable "source_ami_name_filter_arm64" {
  description = "Name filter for the source arm64 AMI image"
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-*-24.04-arm64-server-*"
}

variable "source_ami_owners_arm64" {
  description = "Owners of the arm64 source AMI image"
  type        = list(string)
  default     = ["099720109477"]
}

#################
# AMI variables #
#################

variable "skip_create_ami" {
  description = "Skip packaging and releasing the AMI"
  type        = bool
  default     = false
}

variable "ami_regions" {
  description = "AWS regions where the AMIs will be published"
  type        = list(string)
  default     = ["us-east-1"]
}

variable "ami_users" {
  description = "Users that will have access to the build AMIs"
  type        = list(string)
  default     = []
}

variable "ami_groups" {
  description = "Groups that will have access to the build AMIs"
  type        = list(string)
  default     = []
}

variable "ami_org_arns" {
  description = "ARNs of organizations that will have access to the built AMIs"
  type        = list(string)
  default     = []
}

variable "ami_ou_arns" {
  description = "ARNs of organizational units that will have access to the built AMIs"
  type        = list(string)
  default     = []
}

variable "ami_tags" {
  description = "Additional tags to apply to the built AMI"
  type        = map(string)
  default     = {}
}

###################
# Build variables #
###################

variable "build_region" {
  description = "Region in which to launch EC2 instances to create the AMIs"
  type        = string
  default     = "us-east-1"
}

variable "build_instance_type_x86_64" {
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

variable "build_assign_public_ip_address" {
  description = "Controls if the EC2 instances will be publicly accessible"
  type        = bool
  default     = true
}

variable "build_security_group_cidrs" {
  description = "List of IPv4 CIDR blocks authorized to access to the instance"
  type        = list(string)
  default     = null
}

variable "build_security_group_source_public_ip" {
  description = "Use public IP of the host as allowed inbound CIDR"
  type        = bool
  default     = true
}

variable "build_iam_instance_profile" {
  description = "IAM instance profile to use when launching EC2"
  type        = string
}

variable "user_data_file" {
  description = "Optional file that will be used as user data script when launching EC2"
  type        = string
  default     = null
}

variable "build_tags" {
  description = "Tags to apply to build resources and the resulting AMI"
  type        = map(string)
  default     = {}
}

##########################
# Communicator variables #
##########################

variable "ssh_interface" {
  description = "Specifies how to connect to the remote EC2 instances"
  type        = string
  default     = "session_manager"
}

variable "ssh_username" {
  description = "The username to use when connecting over SSH"
  type        = string
  default     = "ubuntu"
}
