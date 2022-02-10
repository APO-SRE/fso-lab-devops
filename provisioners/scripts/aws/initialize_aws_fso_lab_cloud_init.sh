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
iks_cluster_name="${iks_cluster_name:-AppD-FSO-Lab-01-IKS}"
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

# public key from appdynamics channel sales team account for ed barberis.
aws_cloud9_key_name_01="ed.barberis+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_01="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeV+SMmfQyUXpr9SfKDMZg0QWTg5X/ymBv0Yu7dDkDCzLRJRoQpJh2Dk3/Aumegz1sxyWQnha5Lfpj9sE2tYq6k9qJnCF1efsEG8Lgc3wyBojNfiW6v8N5ekn9ZqzodC+rNhteTitI5BePvnTZmWJBNmz5aUUlQKfQqtSgW/xJy7mWsGzHgLkUhcaFjfugOW1zDkSEJdqclAFhVhnYbxuM4ecF1LiS5iWy2I/BenysUyN9ChFVhMtYSNORDo/0E4ftti+iFPbbupzGyE2nwCIc4SammIOEqm7DLwmUBfxI47d5KP+DNv0ycYWNQam3Sq8EJmLty71KnTXq+hitV6e+YHEzk8eoIdGALTcvKgyhcRXzPIIeKqSfPeN6zd3jHQsKt9/8FFAOfhNHdBGMNDulHRwpPG3thtcH/RWcr599sIAeTEy1DG5acFW0rtLJYM4hXCvuy0eN2JrUEAzBxWu9+iAXKKnWNFZhlafZEfUyMFyON6cbrMwt0TqFSnB1FQcDu5X/H+mGlySTz0bmxedxv7mwmQ3t+xc5VF0RMmzp3mvs3pdsD4g7qm7/hyzYtgoso1OjM2PekqLIY8Hn/0kR0yRlXZm3Ko5ODY0KKFHWb+xTwmDYjIjppsgE9IrrhSRORLcAhLPZzYCOK4Eq2/wYh9kDGU7GV2MxbUoX9a4jRw== ed.barberis+975944588697@cloud9.amazon.com"

# public key from appdynamics channel sales team account for the fso lab user.
aws_cloud9_key_name_02="fso-lab-user+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_02="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrb6DLRU3mchUIfvLw5PmYc7q8hruzW656T6OOo2oSUBrg7FdE3/tgK9eSxss0be1/i89lqFg2tOtmpMt6SMep0rqKjiXCKMDJuAn7lalJd8KG92GKQ/tzlO0naCQMxeS0AMA06TDNTy/Hrmnn3xN5VfuTRFJWQ3xO+m7Oj6l2k3J341pBQe0t0MCShWBsjLg6X0FvQgTxBpUIVt3R6EbhsziggEFMbvM3NBZOa4r3Xz8e00MG5MGpCCyB7tQfpqt79k+7Y0sxd46i+OOnM9o0zWB0b6UpGT9vhoIuGiSibBZrKcrJEZtQxv/LME2N54xaTKvZcZTTXITFYvXr+kP8bwXT6ZkXSkY9kTaDrGFJENFDCAq+Mwqc5EObSSOalITrTzXIB4o9mFj8fELJptg0xIBl80l9/TC89TUJBqQV0HL6PCAoAElUU6CHV1u9ox2N7ZiuoDgf9Lz32h4KzZFzEhlGXg7qyHbbNflfcJz5NloEKAc+ZPgz3VgkxTKhGqOocI7zzIWpfk3t55w/04jkDAIA7bC9TXZ6A0RFy3jrMIY17MSusWrLBtOiE6h0tEYAgkNvCSydrX/04RoRIdPSEiYctZW+h9a67dut976OO6Q2SGV0Y3+4Mvs/s9fDDb7ba4BErX2hwurP1Rcsk6zBrBO50sQWA30gayU1tE4RBw== fso-lab-user+975944588697@cloud9.amazon.com"

# public key from appdynamics channel sales team account for james schneider.
aws_cloud9_key_name_03="james.schneider+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_03="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsaMxabVbUscPI8I/f0yecMQWdCKlmrIeLN4bDTuAQpEZS3BHXx+hr1I/i6xi4K7gxLYyQN/wQwEX8J4YJhgM1xTIYlkKoI9BqRRLqjjm1Z4bPnVUR8GtTvF3A0Z0Aecua3zCig8Vw6nNPM12HjV9KptCSqX0fRyKjUVIMax7mmj1kvGgkeT6SeG/l5JJlnVXSWhitiWthFLyZ7wM5iodo1q4yiyqUNh/GgV1Xf4/puEhXwdSK30NLD2aoqZKh/bejntUMdw66VAlon1PtvSDpbUQqlelyMnwnoOgYE23hlVmBhg3hJX5guXhBxjANuRTezY8U7/mp2BFgnlpbi45vGqWA0tAyI8obFNXPB79gYOYVJ1vGb5O2SXMp0NelhhEQ3LUZVU1SyvjGgD+HLv33J+sZrvJxoNP2aVnwgh7hSWyXq+Taqa4Z3afVBaEuI7S6/uIAGOYlq/gvSBLlqthoMV6ZA83cMXoMfHqTOarmUrwJzhJumDUuITNmuJclyHs+YRGaoBoisFtKl7uFoGHNpYQy2iQshcK42xkltvMUxgpDubK+NADAJB0k2XEoQeuQFQVbNdVlKcr/PCMM4tlb1qNoqwX3ERtEikygHVfM+3ngF+MMUcLF9rGdPfiDwaeKSbKEHbYjXb2bAhF5Rz9cp0aEpfOVbzYFjKp2SF5WVw== james.schneider+975944588697@cloud9.amazon.com"

# public key from appdynamics channel sales team account for ramiro nagles.
aws_cloud9_key_name_04="ramiro.nagles+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_04="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDvQW+ic6k00u5auvPMhE5xzmxL5dQlRHjK6kay5LRAP4tmrLRWpanOaAjvaxc+4Rhxg4fjJSaGWTB83phEYfbqeLM0FcQTjB2gywdWSl861NU3QA5oE1gA7z4OV1DD2exiqNX38gOe+y7+wJqf0yyOiaQv2ghrOgNq/38mZe5RuXCZJsqGO6221CcR6WtxAZPdYuSI9bz7f2oLaD2nMry7MZ8fJ/4xkAyjTt2lr4OIEc0Tf2o9NzS2JQBLbbmAZXDOsUvx1C2VITABi46o1keQa0ifLbCSeFKitlJV+jKV6vukiFdokcfmyZrU+Lsf7m5mjWAt0HDxj5xB0xLBpEDVhaCJZ/HoSFgpmu6b3VmZlKiSZooQPpizkZpwoI26i1YJ05m4kWjbW4tfblpnqxJyOu5g+nXCiPdILo8nc9vixtDL8XZ57z2cH0DzqTNFUhnv5N+21SOP27xDba7QzGILP/Ja90XTpok7n+e3w0LRZANJCljDNLsNdBT00/RXkgGkLOhIV6karHps8hCmVCEA5PZqPA4yw2xB/tTA81RTbXuRD0fwVTWfQx7vtJ5sCshsVgI7hDvvfByw9fVsgsxzVtKiSzSFD6tXH+7ZU1Mah2mrEHwf8NON/5PuHpHp4wv9cTCnBpKOU8O8/kWRROHFZ50jlCzFfRnQvj1S6t1M3Q== ramiro.nagles+975944588697@cloud9.amazon.com"

# public key from appdynamics channel sales team account for wayne brown.
aws_cloud9_key_name_05="wayne.brown+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_05="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2SOn8ufZigQiiHz+d4ijkgA3g97/PAYi3QfMtW7XzT/t0sHcQ4a9wKVN69YZN4skIzh1FwklzwlhOelvWuJWQ8l3vSPsgObF0hLyYIo9+E9n7OCUveHZvSLZS8duCbHazSQRKKCkHvtg0Vwx8Zyn889bypvEB+UvoAUGOoJchc9+ntUZ+DsaduSD+Xm6YnE0oIQBe6TDyZzAWGfCanfUg7q0Rpri9MlOEed0TyAHFDtVG9qyK3co/wilZcrGDQWTphbQEpUOJ/IYnqlcnpnu/u5pqMAu/Cx958/JgUR1EZI3wwslTLmPINQTg7dJ45VIcqAhcoIabPk99RpeQhDKK2A0/Slyn0wtp4oTru0leYXJl3ZzR2oa7R4pEAeoI2kuv5z8FTIQVuxHSLmoi9zXuV6HVSW1ovKwNllASk4nRg4+9zpjE6QcH9CM0vLH28fRhqtguO0T5kA6HgvUJGuVv7MAG5jL/dXQOYLhXSUFsgviyKzr/Lf/Ww3PPdoClpS3f2W5NqT7ofvpIp7mgWf++B7+b1vJLMosY7ARUrBbA0jdZO9Z3vQ8Ly5IwqfGEYmrM08NhMFumDKgB33eJueoAELrhllmA6WLN04yAaNzC7twVIo9D0/sg1FjVMzYodRAS7aIYQSbRrvsZRCRqfgA+g1H65ME4WQuEWPAyX2znxw== wayne.brown+975944588697@cloud9.amazon.com"

# public key from cisco sre sales team account for the admin user (jeff teeter).
aws_cloud9_key_name_06="admin+496972728175@cloud9.amazon.com"
aws_cloud9_public_key_06="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmqdLr5IM9GK15/RXrWyuoh0eVG50BIjIJwzgrjFIujQIMeuMS83h6jQV5Lqd3H3xMlUiRYErTAmnjAqtbA2C5klabPC4UiJjP2W9HQYmUh5Dp2mWW09RIsa0BfRF7oTgCjOxIai2r0cVk9YSFaIylz3KwFmDR7r1Jt6pAdyZzTvHrxDnUZX5XLFOx/h1If8vboEeenTk/B6NSX9s8RfnaFk31G9Bjosa733fgTUK7epYt7ArNnQyUhFRwBs+mDbxp95nlNrT5ASfJQzpAJdjRUOh3YEY8S3vbEEp5T9qMxehfqnrIfLN1NJSgUhAXovBTJLMv4cntHAjilbNKnr0yW1l4tKHKYOowuBHJ5drDcr1c8VkHtKhuLeqUpKdyK2A597Zr5f5fEoDHCZw16gzDuvLM9LhsDoh/U9OfSFuTBbnq5dPSpC1EYFmTU0Ws6OAlMFCYSzbFBl1dG30cbu+HI5Tvz1mUinajiRK9Txld24HSi7IAgQMv2fykeZFL5eWNW2C1wnHuSHYh8qVbU1StCRGcM4yQi8fOb1N9ZwHR/OpYixp2y3mjYSN8m1Z64gvGUv/ID1i+/mt1Fc0ip30YxegZW1knZNJOMta3KHm/0ef5qMQ1wfn0uJS1GcUE1ZPxAoMARuycwJm/iyMjDYWFr3Cf2NSa7fQ8uqch3wugbw== admin+496972728175@cloud9.amazon.com"

# 'grep' to see if the aws cloud9 public key is already present, if not, append to the file.
grep -qF "${aws_cloud9_key_name_01}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_01}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_02}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_02}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_03}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_03}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_04}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_04}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_05}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_05}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_06}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_06}}" >> ${user_authorized_keys_file}
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
sed -i -e "/^eks_kubeconfig_filepath/s/^.*$/eks_kubeconfig_filepath=\"\$HOME\/.kube\/config\"/" ${user_bash_config_file}
sed -i -e "/^iks_cluster_name/s/^.*$/iks_cluster_name=\"${iks_cluster_name}\"/" ${user_bash_config_file}
sed -i -e "/^iks_kubeconfig_filepath/s/^.*$/iks_kubeconfig_filepath=\"\$HOME\/${iks_kubeconfig_file}\"/" ${user_bash_config_file}
sed -i -e "/^fso_lab_number/s/^.*$/fso_lab_number=\"${fso_lab_number}\"/" ${user_bash_config_file}

# configure the hostname of the aws ec2 instance. --------------------------------------------------
# export environment variables.
export aws_ec2_hostname
export aws_ec2_domain

# set the hostname.
./config_al2_system_hostname.sh
