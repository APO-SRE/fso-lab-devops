#!/bin/sh -eux
#---------------------------------------------------------------------------------------------------
# Create FSO Lab User with associated Group and Policies.
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
aws_user_password="${aws_user_password:-C1sc0Fso2022!}"
aws_group_name="${aws_group_name:-fso-lab-group}"
aws_policy_name="${aws_policy_name:-FSOLabTEAgentDeployment}"

# define usage function. ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:
  NOTE: All inputs are defined by external environment variables.
        Script should be run with installed user privilege (i.e. 'non-root' user).
        User should have pre-configured AWS CLI.

  Description of Environment Variables:
    [ubuntu]$ export aws_user_name="fso-lab-user"               # [optional] fso lab user name.
    [ubuntu]$ export aws_user_password="<custom_password_here>" # [optional] fso lab user password.
    [ubuntu]$ export aws_group_name="fso-lab-group"             # [optional] fso lab group name.
    [ubuntu]$ export aws_policy_name="FSOLabTEAgentDeployment"  # [optional] aws policy name for thousandeyes agent.

  Example:
    [ubuntu]$ $0
EOF
}

# validate environment variables. ------------------------------------------------------------------
# check if aws group already exists.
aws_group=$(aws iam list-groups | jq -r --arg AWS_GROUP_NAME "${aws_group_name}" '.Groups[] | select(.GroupName | contains($AWS_GROUP_NAME)) | .GroupName')

if [ ! -z "$aws_group" ]; then
  echo "Error: aws_group_name: ${aws_group_name} already exists."
  usage
  exit 1
fi

# check if aws user already exists.
aws_user=$(aws iam list-users | jq -r --arg AWS_USER_NAME "${aws_user_name}" '.Users[] | select(.UserName | contains($AWS_USER_NAME)) | .UserName')

if [ ! -z "$aws_user" ]; then
  echo "Error: aws_user_name: ${aws_user_name} already exists."
  usage
  exit 1
fi

# create fso lab group and attach group policies. --------------------------------------------------
# create fso lab group.
aws iam create-group --group-name ${aws_group_name}

# create custom thousandeyes agent deployment policy.
cd $HOME/provisioners/scripts/aws/policies/
aws_account_id=$(aws sts get-caller-identity --query "Account" --output text)
sed -e "s/AWS_ACCOUNT_ID/${aws_account_id}/g" FSOLabTEAgentDeployment.json.template >| FSOLabTEAgentDeployment.json
aws iam create-policy --policy-name ${aws_policy_name} --policy-document file://FSOLabTEAgentDeployment.json

# attach group policies to fso lab group.
aws iam attach-group-policy --group-name ${aws_group_name} --policy-arn arn:aws:iam::${aws_account_id}:policy/${aws_policy_name}
aws iam attach-group-policy --group-name ${aws_group_name} --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
aws iam attach-group-policy --group-name ${aws_group_name} --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam attach-group-policy --group-name ${aws_group_name} --policy-arn arn:aws:iam::aws:policy/AWSCloud9EnvironmentMember

# create fso lab user.
aws iam create-user --user-name ${aws_user_name}
aws iam create-login-profile --user-name ${aws_user_name} --password "${aws_user_password}" --no-password-reset-required

# add fso lab user to fso lab group. ---------------------------------------------------------------
aws iam add-user-to-group --group-name ${aws_group_name} --user-name ${aws_user_name}

# print completion message.
echo "FSO Lab User creation complete."
