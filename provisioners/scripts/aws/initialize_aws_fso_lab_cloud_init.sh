#!/bin/sh -eux
# appdynamics aws fso lab cloud-init script to initialize aws ec2 instance launched from ami.

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] aws user and host name config parameters [w/ defaults].
user_name="${user_name:-ec2-user}"
aws_ec2_hostname="${aws_ec2_hostname:-fso-lab-vm}"
aws_ec2_domain="${aws_ec2_domain:-localdomain}"
aws_region_name="${aws_region_name:-us-west-1}"
use_aws_ec2_num_suffix="${use_aws_ec2_num_suffix:-true}"
aws_eks_cluster_name="${aws_eks_cluster_name:-fso-lab-xxxxx-eks-cluster}"
iks_kubeconfig_file="${iks_kubeconfig_file:-AppD-FSO-Lab-01-IKS-kubeconfig.yml}"
lab_number="${lab_number:-1}"

# configure public keys for specified user. --------------------------------------------------------
user_home=$(eval echo "~${user_name}")
user_authorized_keys_file="${user_home}/.ssh/authorized_keys"
user_key_name="FSO-Lab-DevOps"
user_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/wWW+/qc7amCKl/xVrNdVtbSUtWniw5CVHChWqIJU0vef8nQESLU6RPot54r6gzjfNegQFNqaJL+F9JeDVRZ1jYl78+yvmJMCX2ylNIJlfe/owHcFjzWdfDafeusktwifoMSEvc+KouGQinDrrWE5LC8XXkxWjQIwR0Dzv1W/BoiwpPf1F78w2HRRmTkJ6IwSC3Bry0IfmPKTi9OxBAuzJ34gzxIjeb/U8jEABLs0MIkZ8qpVh1s7lv1c7rZ7y3is+fdEqhPeTr03zjIiKerer/5yjjYKE3nsGqEGSQjwrVDw5aEQmtTRBY6G6usP9PLQaRwncJulXngr1k7E7qcz FSO-Lab-DevOps"

# 'grep' to see if the user's public key is already present, if not, append to the file.
grep -qF "${user_key_name}" ${user_authorized_keys_file} || echo "${user_public_key}}" >> ${user_authorized_keys_file}
chmod 600 ${user_authorized_keys_file}

# appdynamics channel sales team account.
aws_cloud9_key_name_01="ed.barberis+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_01="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeV+SMmfQyUXpr9SfKDMZg0QWTg5X/ymBv0Yu7dDkDCzLRJRoQpJh2Dk3/Aumegz1sxyWQnha5Lfpj9sE2tYq6k9qJnCF1efsEG8Lgc3wyBojNfiW6v8N5ekn9ZqzodC+rNhteTitI5BePvnTZmWJBNmz5aUUlQKfQqtSgW/xJy7mWsGzHgLkUhcaFjfugOW1zDkSEJdqclAFhVhnYbxuM4ecF1LiS5iWy2I/BenysUyN9ChFVhMtYSNORDo/0E4ftti+iFPbbupzGyE2nwCIc4SammIOEqm7DLwmUBfxI47d5KP+DNv0ycYWNQam3Sq8EJmLty71KnTXq+hitV6e+YHEzk8eoIdGALTcvKgyhcRXzPIIeKqSfPeN6zd3jHQsKt9/8FFAOfhNHdBGMNDulHRwpPG3thtcH/RWcr599sIAeTEy1DG5acFW0rtLJYM4hXCvuy0eN2JrUEAzBxWu9+iAXKKnWNFZhlafZEfUyMFyON6cbrMwt0TqFSnB1FQcDu5X/H+mGlySTz0bmxedxv7mwmQ3t+xc5VF0RMmzp3mvs3pdsD4g7qm7/hyzYtgoso1OjM2PekqLIY8Hn/0kR0yRlXZm3Ko5ODY0KKFHWb+xTwmDYjIjppsgE9IrrhSRORLcAhLPZzYCOK4Eq2/wYh9kDGU7GV2MxbUoX9a4jRw== ed.barberis+975944588697@cloud9.amazon.com"

# cisco sre sales team account.
aws_cloud9_key_name_02="admin+496972728175@cloud9.amazon.com"
aws_cloud9_public_key_02="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmqdLr5IM9GK15/RXrWyuoh0eVG50BIjIJwzgrjFIujQIMeuMS83h6jQV5Lqd3H3xMlUiRYErTAmnjAqtbA2C5klabPC4UiJjP2W9HQYmUh5Dp2mWW09RIsa0BfRF7oTgCjOxIai2r0cVk9YSFaIylz3KwFmDR7r1Jt6pAdyZzTvHrxDnUZX5XLFOx/h1If8vboEeenTk/B6NSX9s8RfnaFk31G9Bjosa733fgTUK7epYt7ArNnQyUhFRwBs+mDbxp95nlNrT5ASfJQzpAJdjRUOh3YEY8S3vbEEp5T9qMxehfqnrIfLN1NJSgUhAXovBTJLMv4cntHAjilbNKnr0yW1l4tKHKYOowuBHJ5drDcr1c8VkHtKhuLeqUpKdyK2A597Zr5f5fEoDHCZw16gzDuvLM9LhsDoh/U9OfSFuTBbnq5dPSpC1EYFmTU0Ws6OAlMFCYSzbFBl1dG30cbu+HI5Tvz1mUinajiRK9Txld24HSi7IAgQMv2fykeZFL5eWNW2C1wnHuSHYh8qVbU1StCRGcM4yQi8fOb1N9ZwHR/OpYixp2y3mjYSN8m1Z64gvGUv/ID1i+/mt1Fc0ip30YxegZW1knZNJOMta3KHm/0ef5qMQ1wfn0uJS1GcUE1ZPxAoMARuycwJm/iyMjDYWFr3Cf2NSa7fQ8uqch3wugbw== admin+496972728175@cloud9.amazon.com"

# 'grep' to see if the aws cloud9 public key is already present, if not, append to the file.
grep -qF "${aws_cloud9_key_name_01}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_01}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_02}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_02}}" >> ${user_authorized_keys_file}
chmod 600 ${user_authorized_keys_file}

# delete public key inserted by packer during the ami build.
sed -i -e "/packer/d" ${user_authorized_keys_file}

# configure fso lab environment variables for user. ------------------------------------------------
# set current date for temporary filename.
curdate=$(date +"%Y-%m-%d.%H-%M-%S")

# set fso lab environment configuration variables.
user_bash_config_file="${user_home}/.bashrc"
fso_lab_number="$(printf '%02d' ${lab_number})"

# save a copy of the current file.
if [ -f "${user_bash_config_file}.orig" ]; then
  cp -p ${user_bash_config_file} ${user_bash_config_file}.${curdate}
else
  cp -p ${user_bash_config_file} ${user_bash_config_file}.orig
fi

# use the stream editor to substitute the new values.
sed -i -e "/^aws_region_name/s/^.*$/aws_region_name=\"${aws_region_name}\"/" ${user_bash_config_file}
sed -i -e "/^aws_eks_cluster_name/s/^.*$/aws_eks_cluster_name=\"${aws_eks_cluster_name}\"/" ${user_bash_config_file}
sed -i -e "/^iks_kubeconfig_filepath/s/^.*$/iks_kubeconfig_filepath=\"\$HOME\/${iks_kubeconfig_file}\"/" ${user_bash_config_file}
sed -i -e "/^fso_lab_number/s/^.*$/fso_lab_number=\"${fso_lab_number}\"/" ${user_bash_config_file}

# configure the hostname of the aws ec2 instance. --------------------------------------------------
# export environment variables.
export aws_ec2_hostname
export aws_ec2_domain

# set the hostname.
./config_al2_system_hostname.sh
