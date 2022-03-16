#!/bin/sh -eux
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
# NOTE: Script should be run as the installed user with 'sudo' privilege.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
user_name="${user_name:-$(whoami)}"                         # current user name.
export user_name
user_group="${user_group:-$(groups | awk '{print $1}')}"    # current user group name.
export user_group
user_home="${user_home:-$(eval echo "~${user_name}")}"      # current user home folder.
export user_home
devops_home="${devops_home:-${user_home}/fso-lab-devops}"   # fso lab devops home folder.
export devops_home

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
sudo rm -Rf ${devops_home}/provisioners

# download, build, and install vim 8 text editor from source.
curl -fsSL https://raw.githubusercontent.com/APO-SRE/fso-lab-devops/main/provisioners/scripts/ubuntu/install_ubuntu_vim_8.sh -o install_ubuntu_vim_8.sh
chmod 755 ./install_ubuntu_vim_8.sh
sudo ./install_ubuntu_vim_8.sh
rm -f ./install_ubuntu_vim_8.sh

# create default command-line environment profile for the current user.
curl -fsSL https://raw.githubusercontent.com/APO-SRE/fso-lab-devops/main/provisioners/scripts/common/install_user_env.sh -o install_user_env.sh
chmod 755 ./install_user_env.sh
sudo -E ./install_user_env.sh
rm -f ./install_user_env.sh

# use the stream editor to update the correct 'devops_home'.
sed -i -e "/^devops_home/s/^.*$/devops_home=\"${devops_home}\"/" .bashrc

# change ownership of any 'root' owned files and folders.
sudo chown -R ${user_name}:${user_group} .

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
vim --version | awk 'FNR < 3 {print $0}'

# unset user environment variables. ----------------------------------------------------------------
unset user_name
unset user_group
unset user_home
unset devops_home
unset GIT_HOME
unset PATH

# print completion message.
echo "FSO Lab Tools installation complete."
