# Packer Configuration for Creating GraphDB AMI

This guide explains how to use Packer to create an Amazon Machine Image (AMI) for GraphDB.
The Packer configuration in this repository automates the process of installing and configuring GraphDB on an Ubuntu-based EC2 instance.

## Prerequisites

Before you begin, make sure you have the following prerequisites in place:

1. **Packer**: Ensure that you have Packer installed on your local machine.
   You can download it from the official Packer website: [Packer Downloads](https://www.packer.io/downloads).
2. **AWS Account**: You should have an AWS account with necessary permissions to create EC2 instances and AMIs.
3. **AWS VPC**: You should create a VPC, required by Packer to create a temporary security group within the VPC
4. **AWS Subnet**: You should create a public subnet, required by Packer to launch the EC2 instances.

Please note that if you are using an account with the global "Always encrypt new EBS volumes" option set to true,
Packer will be unable to override this setting, and the final image will be encrypted whether you set this value or not.
To build public AMI image this option should be set to `false`.

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
    gdb_version                   = "10.3.3"
    build_aws_regions             = ["us-east-1"]
    build_vpc_id                  = "<your-vpc-id>"
    build_subnet_id               = "<your-subnet-id>"
    ami_groups                    = []                                                    # Value "all" will make the AMI public
    build_instance_type_x86-64    = "t3.small"                                            # default
    build_instance_type_arm64     = "t4g.small"                                           # default
    source_ami_name_filter_arm64  = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-arm64-server-*" # default
    source_ami_name_filter_x86-64 = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*" # default
   ```

4. **Build the AMI**:

   Run Packer to build the AMI:
   ```bash
   packer build -var-file="variables.pkrvars.hcl" .
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
- **AMI Groups**: You can specify the groups the AMIs will be made available to via the `ami_groups` variable.
  A list of strings is accepted.
- **iam_instance_profile**: AIM Instance profile required for the session manager access.
  See https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs#session-manager-connections
- **Network Configuration**: Update the `build_vpc_id` and `build_subnet_id` variables to match your VPC and subnet settings.
- **Source AMI**: Use the `source_ami_name_filter_arm64` and `source_ami_name_filter_x86-64` variables to specify the
    source ami name filter for each AMI, for example:
    - `"ubuntu/images/hvm-ssd/ubuntu-*-22.04-arm64-server-*"` - Ubuntu with `arm64` architecture.
    - `"ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"` - Ubuntu with `amd64` architecture.
- **Provisioning Scripts**: You can replace or modify the provisioning scripts located in the `./files/` directory.
  These scripts and files are copied and executed during the AMI creation process.

## Support

For questions or issues related to this Packer configuration, please [submit an issue](https://github.com/Ontotext-AD/packer-aws-graphdb/issues).
