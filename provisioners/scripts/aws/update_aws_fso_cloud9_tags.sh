#!/bin/bash
#---------------------------------------------------------------------------------------------------
# Update AWS FSO Cloud9 environment tags.
#
# AWS Cloud9 is a cloud-based integrated development environment (IDE) that lets you write, run,
# and debug your code with just a browser. It includes a code editor, debugger, and terminal.
# Cloud9 comes prepackaged with essential tools for popular programming languages, including
# JavaScript, Python, PHP, and more, so you don’t need to install files or configure your
# development machine to start new projects.
#
# A tag is a label or attribute that you or AWS attaches to an AWS resource. Each tag consists of
# a key and a paired value. You can use tags to control access to your AWS Cloud9 resources, as
# described in Control Access Using AWS Resource Tags in the IAM User Guide. Tags can also help
# you manage billing information, as described in User-Defined Cost Allocation Tags.
#
# For more details, please visit:
#   https://aws.amazon.com/cloud9/
#   https://docs.aws.amazon.com/cloud9/latest/user-guide/tags.html
#
# NOTE: All inputs are defined by external environment variables.
#       Script should be run with installed user privilege (i.e. 'non-root' user).
#       User should have pre-configured AWS CLI and 'jq' command-line JSON processor.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] update cloud9 memberships parameters [w/ defaults].
aws_region_name="${aws_region_name:-us-west-1}"
fso_name_prefix="${fso_name_prefix:-FSO-Lab}"

# retrieve metadata for running fso ec2 instances. -------------------------------------------------
echo "Retrieving metadata for running '${fso_name_prefix}' EC2 instances in '${aws_region_name}'..."
fso_ec2_instances_metadata=$(aws ec2 --region ${aws_region_name} describe-instances --filters "Name=tag-key,Values=Name" "Name=tag-value,Values=*${fso_name_prefix}*VM" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value,InstanceId:InstanceId}" | jq '[.[][]] | sort_by(.Name)')

# check if any running fso ec2 instances were found.
if [ -z "$(echo $fso_ec2_instances_metadata | jq '. | select(length > 0)')" ]; then
  echo "Error: No running '${fso_name_prefix}' EC2 instances found in AWS '${aws_region_name}' region."
  exit 1
fi

# print list of fso ec2 instances metadata.
echo $fso_ec2_instances_metadata | jq '. | select(length > 0)'
echo ""

# create array of names for fso ec2 instances.
fso_ec2_instances_names_array=()
fso_ec2_instances_names_array+=( $(echo $fso_ec2_instances_metadata | jq -r '.[] | .Name') )

#for fso_ec2_instance_name in "${fso_ec2_instances_names_array[@]}"; do
#  echo $fso_ec2_instance_name
#done
#echo ""

# create array of ids for fso ec2 instances.
fso_ec2_instances_ids_array=()
fso_ec2_instances_ids_array+=( $(echo $fso_ec2_instances_metadata | jq -r '.[] | .InstanceId') )

#for fso_ec2_instance_id in "${fso_ec2_instances_ids_array[@]}"; do
#  echo $fso_ec2_instance_id
#done
#echo ""

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
fso_cloud9_envs_metadata=$(aws cloud9 --region ${aws_region_name} describe-environments --environment-ids $all_cloud9_envs --query "environments[*]" | jq -r --arg FSO_NAME_PREFIX "${fso_name_prefix}" '[.[] | select(.name | contains($FSO_NAME_PREFIX)) | {name: .name, arn: .arn}] | sort_by(.name)')

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

# create array of arns for fso cloud9 environments.
fso_cloud9_env_arns_array=()
fso_cloud9_env_arns_array+=( $(echo $fso_cloud9_envs_metadata | jq -r '.[] | .arn') )

#for fso_cloud9_env_arn in "${fso_cloud9_env_arns_array[@]}"; do
#  echo $fso_cloud9_env_arn
#done
#echo ""

# add ec2 instance tags to cloud9 environment. -----------------------------------------------------
# loop for each fso cloud9 environment name,
# initialize cloud9 array index.
ii=0
num_updated_fso_cloud9_envs=0
for fso_cloud9_env_name in "${fso_cloud9_env_names_array[@]}"; do
  # initialize ec2 instance array index.
  jj=0

  # loop for each ec2 instance name,
  for fso_ec2_instance_name in "${fso_ec2_instances_names_array[@]}"; do
    fso_ec2_tags_metadata=""

    # does the cloud9 env name match the ec2 instance name?
    if [ "${fso_cloud9_env_name:0:${#fso_cloud9_env_name}-6}" == "${fso_ec2_instance_name:0:${#fso_ec2_instance_name}-2}" ]; then
      fso_ec2_tags_metadata=$(aws ec2 --region ${aws_region_name} describe-tags --filters "Name=resource-id, Values=${fso_ec2_instances_ids_array[$jj]}" | jq '. | del(.Tags[] | select(.Key == "Name")) | del(.Tags[].ResourceId, .Tags[].ResourceType)')
#     echo "${fso_cloud9_env_name} belongs to: ${fso_ec2_instance_name}..."

      if [ ! -z "$(echo $fso_ec2_tags_metadata | jq '[.Tags[]] | select(length > 0)')" ]; then
#       echo $fso_ec2_tags_metadata | jq '.'
#       echo ""

        # add ec2 instance tags to cloud9 environment.
        echo "Adding EC2 instance tags from: '${fso_ec2_instance_name}' to Cloud9 env: '${fso_cloud9_env_name}'..."
        aws cloud9 --region ${aws_region_name} tag-resource --resource-arn ${fso_cloud9_env_arns_array[$ii]} --cli-input-json "${fso_ec2_tags_metadata}"
        num_updated_fso_cloud9_envs=$(($num_updated_fso_cloud9_envs + 1))
      fi
    fi

    # increment ec2 instance array index.
    jj=$(($jj + 1))
  done

  # increment cloud9 array index.
  ii=$(($ii + 1))
done

echo ""
echo "Number of '${fso_name_prefix}' Cloud9 environments updated: '${num_updated_fso_cloud9_envs} of ${#fso_cloud9_env_names_array[@]}'."
echo ""

# print completion message. ------------------------------------------------------------------------
echo "Update '${fso_name_prefix}' Cloud9 environment tags in '${aws_region_name}' operation complete."
