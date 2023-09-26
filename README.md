# Packer Configuration for Creating GraphDB AMI

This guide explains how to use Packer to create an Amazon Machine Image (AMI) for GraphDB. 
The Packer configuration in this repository automates the process of installing and configuring GraphDB on an Ubuntu-based EC2 instance.

## Prerequisites

Before you begin, make sure you have the following prerequisites in place:

1. **Packer**: Ensure that you have Packer installed on your local machine.
2. You can download it from the official Packer website: [Packer Downloads](https://www.packer.io/downloads).

2. **AWS Account**: You should have an AWS account with necessary permissions to create EC2 instances and AMIs.

## Usage

Follow these steps to build an AMI for GraphDB using Packer:

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/Ontotext-AD/packer-aws-graphdb.git
   ```

2. **Set Your AWS Credentials**:

   Ensure that your AWS credentials are correctly configured in the AWS CLI configuration.

3. **Edit Variables (Optional)**:

   The Packer configuration allows you to customize various parameters, such as the GraphDB version, AWS region, 
   instance type, VPC ID, and subnet ID. To do so, create a variables file `variables.pkrvars.hcl`, example file: 

   ```bash
   gdb_version  = "10.3.3"
   build_aws_regions = ["eu-central-1"]
   build_vpc_id = "<your-vpc-id>"
   build_subnet_id = "<your-subnet-id>"
   build_instance_type_x86-64    = "t3.small"
   build_instance_type_arm64     = "t4g.small"
   source_ami_name_filter_arm64  = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-arm64-server-*"
   source_ami_name_filter_x86-64 = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"
   ```

4. **Build the AMI**:

   Run Packer to build the AMI:

   ```bash
   packer build -var-file="variables.pkrvars.hcl" aws-ami.pkr.hcl
   ```

   This command will initiate the Packer build process. Packer will launch an EC2 instance, install GraphDB, 
   and create an AMI based on the instance.

## Customization

You can customize the Packer configuration and provisioning scripts to suit your specific requirements. 

The following points can be customized in a packer variables file `variables.pkrvars.hcl`:

- **GraphDB Version**: You can change the GraphDB version by modifying the `gdb_version` variable file.

- **AWS Regions**: Modify the `build_aws_region` variable to specify a different AWS region.

- **Instance Type**: Adjust the `build_instance_type_arm64` and `build_instance_type_x86-64` variables to select  
  different EC2 instance types for building the AMI images.

- **Network Configuration**: Update the `build_vpc_id` and `build_subnet_id` variables to match your VPC and subnet settings.

  - **Source AMI**: Use the `source_ami_name_filter_arm64` and `source_ami_name_filter_x86-64` variables to specify the 
    source ami name filter for each AMI, for example: 
    - `"ubuntu/images/hvm-ssd/ubuntu-*-22.04-arm64-server-*"` - Ubuntu with `arm64` architecture. 
    - `"ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"` - Ubuntu with `amd64` architecture.

- **Provisioning Scripts**: You can replace or modify the provisioning scripts located in the `./files/` directory. 
  These scripts and files are copied and executed during the AMI creation process.

## Support

For questions or issues related to this Packer configuration, please [submit an issue](https://github.com/Ontotext-AD/packer-aws-graphdb/issues).
