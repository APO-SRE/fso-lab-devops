#!/bin/sh -eu
#---------------------------------------------------------------------------------------------------
# Create FSO Lab key pair and import to AWS.
#
# A key pair, consisting of a public key and a private key, is a set of security credentials that
# you use to prove your identity when connecting to an Amazon EC2 instance. Amazon EC2 stores the
# public key on your instance, and you store the private key. For Linux instances, the private key
# allows you to securely SSH into your instance. Anyone who possesses your private key can connect
# to your instances, so it's important that you store your private key in a secure place.
#
# For more details, please visit:
#   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
#   https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-keypairs.html
#
# NOTE: All inputs are defined by external environment variables.
#       Script should be run with installed user privilege (i.e. 'non-root' user).
#       User should have pre-configured AWS CLI.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] aws create key pair parameters [w/ defaults].
fso_key_pair_name="${fso_key_pair_name:-FSO-Lab-DevOps}"
aws_region_name="${aws_region_name:-us-west-1}"

# define usage function. ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:
  NOTE: All inputs are defined by external environment variables.
        Script should be run with installed user privilege (i.e. 'non-root' user).
        User should have pre-configured AWS CLI.

  Description of Environment Variables:
    [ubuntu]$ export fso_key_pair_name="FSO-Lab-DevOps"         # [optional] fso lab key pair name.
    [ubuntu]$ export aws_region_name="us-west-1"                # [optional] aws region name.

  Example:
    [ubuntu]$ $0
EOF
}

# validate environment variables. ------------------------------------------------------------------
# check if aws group already exists.
aws_key_pair=$(aws ec2 --region ${aws_region_name} describe-key-pairs --key-name "${fso_key_pair_name}" | jq -r --arg AWS_KEY_PAIR "${fso_key_pair_name}" '.KeyPairs[] | select(.KeyName | contains($AWS_KEY_PAIR)) | .KeyName')

if [ ! -z "$aws_key_pair" ]; then
  echo "Error: fso_key_pair_name: '${fso_key_pair_name}' already exists."
  usage
  exit 1
fi

# create fso lab ssh key pair. ---------------------------------------------------------------------
echo "Creating FSO Lab key pair..."

# generate key pair in pem format.
# we prefer 'ssh-keygen' because you can include a comment with the '-C' option.
echo "ssh-keygen -b 2048 -t rsa -m PEM -C \"${fso_key_pair_name}\" -f $HOME/.ssh/${fso_key_pair_name}"
ssh-keygen -b 2048 -t rsa -m PEM -C "${fso_key_pair_name}" -f $HOME/.ssh/${fso_key_pair_name}

echo "mv $HOME/.ssh/${fso_key_pair_name} $HOME/.ssh/${fso_key_pair_name}.pem"
mv $HOME/.ssh/${fso_key_pair_name} $HOME/.ssh/${fso_key_pair_name}.pem
echo ""

# you can also use the aws cli if you don't have 'ssh-keygen' installed.
# the downside is that you don't get a local copy of the public key.
echo "aws ec2 --region ${aws_region_name} create-key-pair --key-name \"${fso_key_pair_name}\" --query 'KeyMaterial' --output text > $HOME/.ssh/${fso_key_pair_name}.pem"
aws ec2 --region ${aws_region_name} create-key-pair --key-name "${fso_key_pair_name}" --query 'KeyMaterial' --output text > $HOME/.ssh/${fso_key_pair_name}.pem
echo ""

# import fso lab key key pair to aws. --------------------------------------------------------------
echo "aws ec2 --region ${aws_region_name} import-key-pair --key-name \"${fso_key_pair_name}\" --public-key-material fileb://$HOME/.ssh/${fso_key_pair_name}.pub"
aws ec2 --region ${aws_region_name} import-key-pair --key-name "${fso_key_pair_name}" --public-key-material fileb://$HOME/.ssh/${fso_key_pair_name}.pub
echo ""

# verify key pair.
echo "aws ec2 --region ${aws_region_name} describe-key-pairs --key-name \"${fso_key_pair_name}\" | jq '.'"
aws ec2 --region ${aws_region_name} describe-key-pairs --key-name "${fso_key_pair_name}" | jq '.'
echo ""

# print completion message.
echo "FSO Lab key pair creation complete."
