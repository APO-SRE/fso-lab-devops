#!/bin/sh -eux
# install cloud9 binaries for aws amazon linux 2 vms.

# set default values for input environment variables if not set. -----------------------------------
user_name="${user_name:-}"

# set default value for devops home environment variable if not set. -------------------------------
devops_home="${devops_home:-/opt/fso-lab-devops}"

# define usage function. ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:
  All inputs are defined by external environment variables.
  Script should be run with correct privilege for the given user name.
  Example:
    [root]# export user_name="user1"                            # user name.
    [root]# export devops_home="/opt/fso-lab-devops"            # [optional] devops home (defaults to '/opt/fso-lab-devops').
    [root]# $0
EOF
}

# validate environment variables. ------------------------------------------------------------------
if [ -z "$user_name" ]; then
  echo "Error: 'user_name' environment variable not set."
  usage
  exit 1
fi

if [ "$user_name" == "root" ]; then
  echo "Error: 'user_name' should NOT be 'root'."
  usage
  exit 1
fi

# install cloud9 runtime enviroment if os is 'amazon linux 2'. -------------------------------------
user_host_os=$(hostnamectl | awk '/Operating System/ {printf "%s %s %s", $3, $4, $5}')
if [ "$user_host_os" == "Amazon Linux 2" ]; then
  runuser -c "${devops_home}/provisioners/scripts/aws/c9-install.sh" - ${user_name}
fi
