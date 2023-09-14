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
   gdb_version  = "10.3.2"
   build_aws_regions = ["eu-central-1"]
   build_instance_type = "m5.large"
   build_vpc_id = "<your-vpc-id>"
   build_subnet_id = "<your-subnet-id>"
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

- **Instance Type**: Adjust the `build_instance_type` variable to select a different EC2 instance type.

- **Network Configuration**: Update the `build_vpc_id` and `build_subnet_id` variables to match your VPC and subnet settings.

- **Provisioning Scripts**: You can replace or modify the provisioning scripts located in the `./files/` directory. 
  These scripts and files are copied and executed during the AMI creation process.

## Support

For questions or issues related to this Packer configuration, please [submit an issue](https://github.com/Ontotext-AD/packer-aws-graphdb/issues).
