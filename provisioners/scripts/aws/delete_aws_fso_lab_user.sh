#!/bin/sh -eux
#---------------------------------------------------------------------------------------------------
# Delete FSO Lab User with associated Group and Policies.
#
# An AWS Identity and Access Management (IAM) user is an entity that you create in AWS to represent
# the person or application that uses it to interact with AWS. A user in AWS consists of a name and
# credentials.
#
# To simplify workshop provisioning, all lab participants will make use of a single FSO Lab User.
# Each participant will login to the AWS Console in order to access their Cloud9 IDE. Later, they
# will be redirected from the ThousandEyes portal to CloudFormation for deployment of the
# ThousandEyes Enterprise Agent in AWS as instructed in the lab guide.
# 
# For more details, please visit:
#   https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html
#   https://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups.html
#   https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
#
# NOTE: All inputs are defined by external environment variables.
#       Script should be run with installed user privilege (i.e. 'non-root' user).
#       User should have pre-configured AWS CLI.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] aws create user install parameters [w/ defaults].
aws_user_name="${aws_user_name:-fso-lab-user}"
aws_group_name="${aws_group_name:-fso-lab-group}"
aws_policy_name="${aws_policy_name:-FSOLabTEAgentDeployment}"
local_devops_home="${local_devops_home:-${HOME}/fso-lab-devops}"

# define usage function. ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:
  NOTE: All inputs are defined by external environment variables.
        Script should be run with installed user privilege (i.e. 'non-root' user).
        User should have pre-configured AWS CLI.

  Description of Environment Variables:
    [ubuntu]$ export aws_user_name="fso-lab-user"               # [optional] fso lab user name.
    [ubuntu]$ export aws_group_name="fso-lab-group"             # [optional] fso lab group name.
    [ubuntu]$ export aws_policy_name="FSOLabTEAgentDeployment"  # [optional] aws policy name for thousandeyes agent.
    [ubuntu]$ export local_devops_home="${HOME}/fso-lab-devops" # [optional] local devops home environment variable.

  Example:
    [ubuntu]$ $0
EOF
}

# validate environment variables. ------------------------------------------------------------------
# check if aws user exists.
aws_user=$(aws iam list-users | jq -r --arg AWS_USER_NAME "${aws_user_name}" '.Users[] | select(.UserName | contains($AWS_USER_NAME)) | .UserName')

if [ -z "$aws_user" ]; then
  echo "Error: aws_user_name: ${aws_user_name} does NOT exist."
  usage
  exit 1
fi

# check if custom thousandeyes agent deployment policy exists.
# retrieve custom thousandeyes agent deployment policy arn.
aws_policy_arn=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${aws_policy_name}'].Arn" --output json | jq -r '.[]')

if [ -z "$aws_policy_arn" ]; then
  echo "Error: aws_policy_name: ${aws_policy_name} does NOT exist."
  usage
  exit 1
fi

# check if custom thousandeyes agent deployment policy file exists.
if [ ! -f "${local_devops_home}/provisioners/scripts/aws/policies/${aws_policy_name}.json" ]; then
  echo "Error: Can't find ${local_devops_home}/provisioners/scripts/aws/policies/${aws_policy_name}.json file."
  usage
  exit 1
fi

# check if aws group exists.
aws_group=$(aws iam list-groups | jq -r --arg AWS_GROUP_NAME "${aws_group_name}" '.Groups[] | select(.GroupName | contains($AWS_GROUP_NAME)) | .GroupName')

if [ -z "$aws_group" ]; then
  echo "Error: aws_group_name: ${aws_group_name} does NOT exist."
  usage
  exit 1
fi

# remove user from fso lab group and delete fso lab user. ------------------------------------------
aws iam remove-user-from-group --group-name ${aws_group_name} --user-name ${aws_user_name}

# delete fso lab user.
aws iam delete-login-profile --user-name ${aws_user_name}
aws iam delete-user --user-name ${aws_user_name}

# detach group policies and delete fso lab group. --------------------------------------------------
# retrieve custom thousandeyes agent deployment policy arn.
aws_policy_arn=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${aws_policy_name}'].Arn" --output json | jq -r '.[]')

# detach group policies from fso lab group.
aws iam detach-group-policy --group-name ${aws_group_name} --policy-arn ${aws_policy_arn}
aws iam detach-group-policy --group-name ${aws_group_name} --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
aws iam detach-group-policy --group-name ${aws_group_name} --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam detach-group-policy --group-name ${aws_group_name} --policy-arn arn:aws:iam::aws:policy/AWSCloud9EnvironmentMember

# delete custom thousandeyes agent deployment policy.
aws iam delete-policy --policy-arn ${aws_policy_arn}

# delete custom thousandeyes agent deployment policy file.
rm -f "${local_devops_home}/provisioners/scripts/aws/policies/${aws_policy_name}.json"

# delete fso lab group.
aws iam delete-group --group-name ${aws_group_name}

# print completion message.
echo "FSO Lab User deletion complete."
