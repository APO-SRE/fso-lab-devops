#!/bin/bash
#---------------------------------------------------------------------------------------------------
# Update AWS FSO Cloud9 environment memberships.
#
# AWS Cloud9 is a cloud-based integrated development environment (IDE) that lets you write, run,
# and debug your code with just a browser. It includes a code editor, debugger, and terminal.
# Cloud9 comes prepackaged with essential tools for popular programming languages, including
# JavaScript, Python, PHP, and more, so you don’t need to install files or configure your
# development machine to start new projects.
#
# A shared environment membership is an AWS Cloud9 development environment that multiple users
# have been invited to participate in.
#
# For the FSO labs, this script automates the addition of the FSO lab user as well as other AWS
# account 'admin' users in order to facilitate delivery of the FSO lab enablement workshops.
#
# For more details, please visit:
#   https://aws.amazon.com/cloud9/
#   https://docs.aws.amazon.com/cloud9/latest/user-guide/share-environment.html
#
# NOTE: All inputs are defined by external environment variables.
#       Script should be run with installed user privilege (i.e. 'non-root' user).
#       User should have pre-configured AWS CLI and 'jq' command-line JSON processor.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] update cloud9 memberships parameters [w/ defaults].
aws_region_name="${aws_region_name:-us-west-1}"
fso_name_prefix="${fso_name_prefix:-FSO-Lab}"

# retrieve list of all cloud9 environments. --------------------------------------------------------
echo "Retrieving list of all Cloud9 environments in AWS '${aws_region_name}' region..."
all_cloud9_envs=$(aws cloud9 --region ${aws_region_name} list-environments --query "environmentIds[*]" | jq -r '.[]')

# check if any cloud9 environments were found.
if [ -z "$all_cloud9_envs" ]; then
  echo "Error: No Cloud9 environments found in AWS '${aws_region_name}' region."
  exit 1
fi

# print list of cloud9 environment ids.
#echo $all_cloud9_envs
#echo ""

# retrieve metadata for fso cloud9 environments. ---------------------------------------------------
echo "Retrieving metadata for '${fso_name_prefix}' Cloud9 environments in '${aws_region_name}'..."
fso_cloud9_envs_metadata=$(aws cloud9 --region ${aws_region_name} describe-environments --environment-ids $all_cloud9_envs --query "environments[*]" | jq -r --arg FSO_NAME_PREFIX "${fso_name_prefix}" '[.[] | select(.name | contains($FSO_NAME_PREFIX)) | {name: .name, id: .id}] | sort_by(.name)')

# check if any fso cloud9 environments were found.
if [ -z "$(echo $fso_cloud9_envs_metadata | jq '. | select(length > 0)')" ]; then
  echo "Error: No '${fso_name_prefix}' Cloud9 environments found in AWS '${aws_region_name}' region."
  exit 1
fi

# print list of fso cloud9 environment metadata.
echo $fso_cloud9_envs_metadata | jq '. | select(length > 0)'
echo ""

# create array of names for fso cloud9 environments.
fso_cloud9_env_names_array=()
fso_cloud9_env_names_array+=( $(echo $fso_cloud9_envs_metadata | jq -r '.[] | .name') )

#for fso_cloud9_env_name in "${fso_cloud9_env_names_array[@]}"; do
#  echo $fso_cloud9_env_name
#done
#echo ""

# create array of ids for fso cloud9 environments.
fso_cloud9_env_ids_array=()
fso_cloud9_env_ids_array+=( $(echo $fso_cloud9_envs_metadata | jq -r '.[] | .id') )

#for fso_cloud9_env_id in "${fso_cloud9_env_ids_array[@]}"; do
#  echo $fso_cloud9_env_id
#done
#echo ""

# retrieve current aws account id. -----------------------------------------------------------------
echo "Retrieving current AWS Account ID..."
aws_account_id=$(aws sts get-caller-identity --query "Account" --output text)

# check if aws account id was found.
if [ -z "$aws_account_id" ]; then
  echo "Error: AWS Account ID not found."
  exit 1
fi

# print aws account id.
echo "AWS Account ID: '${aws_account_id}'"
echo ""

# create array of user arns to add to cloud9 environment memberships. ------------------------------
# NOTE: cloud9 supports a maximum of 7 shared memberships plus the owner.
echo "Creating array of User ARNs to add to Cloud9 memberships..."
fso_cloud9_user_share_array=()

# create user arns array for appd cisco runon aws account.
if [ "${aws_account_id}" == "395719258032" ]; then
  fso_cloud9_user_share_array+=( "arn:aws:iam::395719258032:user/fso-lab-user" )
  fso_cloud9_user_share_array+=( "arn:aws:iam::395719258032:user/ed.barberis" )
  fso_cloud9_user_share_array+=( "arn:aws:iam::395719258032:user/james.schneider" )
  fso_cloud9_user_share_array+=( "arn:aws:sts::395719258032:assumed-role/admin/ebarberi@cisco.com" )
  fso_cloud9_user_share_array+=( "arn:aws:sts::395719258032:assumed-role/admin/james101@cisco.com" )
# fso_cloud9_user_share_array+=( "arn:aws:iam::395719258032:user/wayne.brown" )
# create user arns array for appd original aws account.
elif [ "${aws_account_id}" == "975944588697" ]; then
  fso_cloud9_user_share_array+=( "arn:aws:iam::975944588697:user/fso-lab-user" )
  fso_cloud9_user_share_array+=( "arn:aws:sts::975944588697:assumed-role/AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96/ed.barberis@appdynamics.com" )
  fso_cloud9_user_share_array+=( "arn:aws:sts::975944588697:assumed-role/AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96/james.schneider@appdynamics.com" )
# fso_cloud9_user_share_array+=( "arn:aws:sts::975944588697:assumed-role/AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96/wayne.brown@appdynamics.com" )
# create user arns array for apo cisco runon aws account.
elif [ "${aws_account_id}" == "496972728175" ]; then
  fso_cloud9_user_share_array+=( "arn:aws:iam::496972728175:user/fso_user" )
  fso_cloud9_user_share_array+=( "arn:aws:iam::496972728175:user/jeff.teeter" )
  fso_cloud9_user_share_array+=( "arn:aws:iam::496972728175:user/justin.weems" )
else
  echo "Error: aws_account_id: IAM users undefined for AWS Account: '${aws_account_id}'."
  exit 1
fi

# print user arns array.
echo "User ARNs:"
for fso_cloud9_user_arn in "${fso_cloud9_user_share_array[@]}"; do
  echo $fso_cloud9_user_arn
done
echo ""

# check to make sure we don't have more than 7 users in the array.
if [ "${#fso_cloud9_user_share_array[@]}" -gt 7 ]; then
  echo "Error: You cannot invite more than 7 members to your environment (8 total-including the owner)."
  exit 1
fi

# add user arns to cloud9 environment membership. --------------------------------------------------
# loop for each user arn,
for fso_cloud9_user_arn in "${fso_cloud9_user_share_array[@]}"; do
  # initialize array index.
  ii=0

  # loop for each fso cloud9 environment arn,
  for fso_cloud9_env_id in "${fso_cloud9_env_ids_array[@]}"; do
    # retrieve fso cloud9 metadata filtered by user arn.
    echo "Checking for user: '${fso_cloud9_user_arn}' in Cloud9 environment: '${fso_cloud9_env_names_array[$ii]}..."
    fso_cloud9_member_metadata=$(aws cloud9 --region ${aws_region_name} describe-environment-memberships --environment-id $fso_cloud9_env_id --query "memberships[*]" | jq -r --arg USER_ARN "${fso_cloud9_user_arn}" '[.[] | select(.userArn | contains($USER_ARN)) | {userArn: .userArn, permissions: .permissions}] | sort_by(.name)')

    # is user arn is already a member of the cloud9 environment?
    if [ -z "$(echo $fso_cloud9_member_metadata | jq '. | select(length > 0)')" ]; then
      echo "Adding user: '${fso_cloud9_user_arn}' to Cloud9 environment: '${fso_cloud9_env_names_array[$ii]}..."
      aws cloud9 --region ${aws_region_name} create-environment-membership --environment-id $fso_cloud9_env_id --user-arn $fso_cloud9_user_arn --permissions read-write | jq '.'
      echo ""
    fi

    # increment array index.
    ii=$(($ii + 1))
  done
done
echo ""

# print completion message. ------------------------------------------------------------------------
echo "Update '${fso_name_prefix}' Cloud9 environments in '${aws_region_name}' operation complete."
