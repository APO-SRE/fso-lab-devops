#!/bin/sh -eux
#---------------------------------------------------------------------------------------------------
# Create FSO Lab key pair and import to AWS.
#
# NOTE: All inputs are defined by external environment variables.
#       Script should be run with installed user privilege (i.e. 'non-root' user).
#       User should have pre-configured AWS CLI.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] aws create key pair parameters [w/ defaults].
fso_key_pair_name="${fso_key_pair_name:-FSO-Lab-DevOps}"
aws_region_name="${aws_region_name:-us-west-1}"

# create fso lab ssh key pair. ---------------------------------------------------------------------
# generate key pair in pem format.
ssh-keygen -b 2048 -t rsa -m PEM -C "${fso_key_pair_name}" -f $HOME/.ssh/${fso_key_pair_name}
mv $HOME/.ssh/${fso_key_pair_name} $HOME/.ssh/${fso_key_pair_name}.pem

# import fso lab key key pair to aws. --------------------------------------------------------------
aws ec2 --region ${aws_region_name} import-key-pair --key-name "${fso_key_pair_name}" --public-key-material fileb://~/.ssh/${fso_key_pair_name}.pub

# verify key pair.
aws ec2 --region ${aws_region_name} describe-key-pairs --key-name "${fso_key_pair_name}" | jq '.'

# print completion message.
echo "FSO Lab Key Pair creation complete."
