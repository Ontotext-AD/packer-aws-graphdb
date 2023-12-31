# Changelog

All notable changes to the Packer template for creating GraphDB AMIs will be documented in this file.

## [1.4.0]

- Installed cloudwatch agent and its needed configurations to be able to push metrics
- Added editorconfig to the project
- Added `yq` utility
- Moved variables block to variables.pkr.hcl
- Moved plugins block to plugins.pkr.hcl
- Moved build block to build.pkr.hcl
- Updated README.md
- Added `ssh_clear_authorized_keys` in favor of shredding them in the installation script.

## [1.3.0]

- Tuned GraphDB's max RAM percentage to allow bigger heap sizes
- Limited the cluster proxy to 1GB heap at most
- Configured GraphDB logs to be within GraphDB's data directory
- Updated the directory structure under /var/opt/graphdb/
- Properly configured the home directories of GraphDB and its proxy
- Removed provisioning of graphdb.properties
- Added `ebs_optimized` to be true
- Added `encrypt_boot` to be false
- Added shredding of `/root/.ssh/authorized_keys` and `/home/ubuntu/.ssh/authorized_keys`

## [1.2.0]

- Added new configuration for AMI groups `ami_groups`
- Changed `ssh_interface` to `session_manager`
- Added `iam_instance_profile` variable required from the `session_manager`
- Added `Build_Timestamp` tag to the AMIs

## [1.1.0]

- Added parallel building of `arm64` and `amd64` based AMIs
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
