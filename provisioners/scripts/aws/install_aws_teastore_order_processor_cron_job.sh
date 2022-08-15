#!/bin/sh -eux
# appdynamics aws fso lab cloud-init script to create order processor cron job.

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] fso lab config parameters [w/ defaults].
user_name="${user_name:-ec2-user}"
aws_region_name="${aws_region_name:-us-west-1}"
aws_eks_cluster_name="${aws_eks_cluster_name:-fso-lab-xxxxx-eks-cluster}"
iks_cluster_name="${iks_cluster_name:-AppD-FSO-Lab-01-IKS}"
iks_kubeconfig_file="${iks_kubeconfig_file:-AppD-FSO-Lab-01-IKS-kubeconfig.yml}"
lab_number="${lab_number:-1}"

# configure order processor cron job variables. ----------------------------------------------------
fso_lab_number="$(printf '%02d' ${lab_number})"
order_processor_cron_job_file="/etc/cron.d/restart-teastore-order-processor"
user_home=$(eval echo "~${user_name}")

# test if directory containing user cron jobs exists. ----------------------------------------------
if [ ! -d "/etc/cron.d" ]; then
  echo "Notice: Directory containing user cron jobs 'etc/cron.d' does NOT exist."
  exit 0
fi

# create order processor cron job file. ------------------------------------------------------------
rm -f ${order_processor_cron_job_file}

cat <<EOF > ${order_processor_cron_job_file}
fso_lab_number=${fso_lab_number}
eks_kubeconfig_filepath=${user_home}/.kube/config
KUBECONFIG=${user_home}/.kube/config
aws_eks_cluster_name=${aws_eks_cluster_name}
aws_region_name=${aws_region_name}
PATH=/usr/local/java/jdk180/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
JAVA_HOME=/usr/local/java/jdk180
iks_kubeconfig_filepath=${user_home}/${iks_kubeconfig_file}
devops_home=/opt/fso-lab-devops
iks_cluster_name=${iks_cluster_name}
0,10,20,30,40,50 * * * * ${user_name} /opt/fso-lab-devops/provisioners/scripts/common/redeploy_teastore_order_processor_to_kubernetes.sh >/dev/null 2>&1
EOF

chmod 644 ${order_processor_cron_job_file}
