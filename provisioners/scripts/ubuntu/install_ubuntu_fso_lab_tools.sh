#!/bin/sh -eu
#---------------------------------------------------------------------------------------------------
# Install FSO Lab tools on Ubuntu linux 64-bit.
#
# To configure the FSO Lab workshop environments, the first step is to set-up your development
# environment by installing the needed software. This script simplifies that process by automating
# the installation of all needed packages.
#
# For Ubuntu, these software utilities include the following:
#   Git:        Git is a distributed version control system.
#   Packer:     Packer is a machine and container image tool by HashiCorp.
#   Terraform:  Terraform is an Infrastructure as Code (IaC) tool by HashiCorp.
#   jq:         jq is a command-line json processor for linux 64-bit.
#   AWS CLI v2: AWS CLI is an open source tool that enables you to interact with AWS services.
#
# For more details, please visit:
#   https://git-scm.com/
#   https://packer.io/
#   https://terraform.io/
#   https://stedolan.github.io/jq/
#   https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html
#
# NOTE: Existing AWS CLI installs may require setting the 'update_aws_cli' variable to 'true'.
#       Script should be run as the installed user with 'sudo' privilege.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
user_name="${user_name:-$(whoami)}"                         # current user name.
export user_name
user_group="${user_group:-$(groups | awk '{print $1}')}"    # current user group name.
export user_group
devops_home="${devops_home:-$(eval echo "~${user_name}")}"  # fso lab devops home folder.
export devops_home
update_aws_cli="${update_aws_cli:-false}"                   # flag to allow 'update' of existing aws cli install.
export update_aws_cli

# install basic utilities needed for the install scripts. ------------------------------------------
# update apt packages for ubuntu.
sudo apt -y update
sudo apt -y upgrade

# install core linux utilities.
sudo apt -y install curl tree wget unzip

# download and install the custom utilities. -------------------------------------------------------
cd ~

# download, build, and install git from source.
curl -fsSL https://raw.githubusercontent.com/APO-SRE/fso-lab-devops/main/provisioners/scripts/ubuntu/install_ubuntu_git.sh -o install_ubuntu_git.sh
chmod 755 ./install_ubuntu_git.sh
sudo -E ./install_ubuntu_git.sh
rm -f ./install_ubuntu_git.sh

# append git environment variables to the user 'bashrc' file.
cat <<EOF >> ~/.bashrc

# set git home environment variables.
GIT_HOME=/usr/local/git/git
export GIT_HOME
PATH=\${GIT_HOME}/bin:\$PATH
export PATH
EOF

# download and install packer by hashicorp.
curl -fsSL https://raw.githubusercontent.com/APO-SRE/fso-lab-devops/main/provisioners/scripts/common/install_hashicorp_packer.sh -o install_hashicorp_packer.sh
chmod 755 ./install_hashicorp_packer.sh
sudo ./install_hashicorp_packer.sh
rm -f ./install_hashicorp_packer.sh

# download and install terraform by hashicorp.
curl -fsSL https://raw.githubusercontent.com/APO-SRE/fso-lab-devops/main/provisioners/scripts/common/install_hashicorp_terraform.sh -o install_hashicorp_terraform.sh
chmod 755 ./install_hashicorp_terraform.sh
sudo ./install_hashicorp_terraform.sh
rm -f ./install_hashicorp_terraform.sh

# download and install jq json processor.
curl -fsSL https://raw.githubusercontent.com/APO-SRE/fso-lab-devops/main/provisioners/scripts/common/install_jq_json_processor.sh -o install_jq_json_processor.sh
chmod 755 ./install_jq_json_processor.sh
sudo ./install_jq_json_processor.sh
rm -f ./install_jq_json_processor.sh

# download and install aws command line interface (cli) 2 by amazon.
curl -fsSL https://raw.githubusercontent.com/APO-SRE/fso-lab-devops/main/provisioners/scripts/common/install_aws_cli_2.sh -o install_aws_cli_2.sh
chmod 755 ./install_aws_cli_2.sh
sudo -E ./install_aws_cli_2.sh
rm -f ./install_aws_cli_2.sh
rm -Rf ${devops_home}/provisioners/scripts/centos

# change ownership of any 'root' owned files and folders.
chown -R ${user_name}:${user_group} .

# verify installations. ----------------------------------------------------------------------------
# set environment variables.
GIT_HOME=/usr/local/git/git
export GIT_HOME
PATH=${GIT_HOME}/bin:/usr/local/bin:$PATH
export PATH

# verify basic utility installations.
curl --version
tree --version
wget --version
unzip -v

# verify custom utility installations.
git --version
packer --version
terraform --version
jq --version
aws --version

# print completion message.
echo "FSO Lab Tools installation complete."
