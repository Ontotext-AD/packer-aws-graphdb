# Packer Template Changelog

All notable changes to the Packer template for creating GraphDB AMIs will be documented in this file.

## [1.1.0]

- Added parallel building of `arm64` and `amd63` based AMIs
- Added AWS cli to be installed based on the architecture
- Added new variables for `arm64` instance type and source AMI  
- Renamed `build_instance_type` and `build_instance_type` variables
- Added default values for `source_ami_name_filter_arm64` and `source_ami_name_filter_x86-64`
- Changed default instance type for x86-64 to `t3.small`
- Added tags to the AMIs

## [1.0.0] 

- Initial release of the Packer template.
- Added configuration to create GraphDB AMIs on AWS.
- Added basic provisioning with installation scripts.
- Added customizable instance type, region, VPC, and subnet.
- Added README.md with usage instructions.
- Added CONTRIBUTING.md
- Added CHANGELOG.md
