#!/bin/bash -eu
#---------------------------------------------------------------------------------------------------
# Redeploy TeaStore Order Processor service to Kubernetes (EKS).
#
# The Order Processor service simulates user interaction with the TeaStore application by randomly
# placing orders for tea. By design, the service also introduces a memory leak which causes the
# service to crash and be restarted by Kubernetes approximately every 15 minutes. After several
# restarts, (many more than 100), Kubernetes seems to mark the service as failed and discontinues
# any attempts to restart.
#
# The purpose of this script is to check the service restart count and automatically delete and
# redeploy the application after a designated number of restarts (default: 100).
#
# For more details, please visit:
#   https://github.com/DescartesResearch/TeaStore
#   https://github.com/DescartesResearch/TeaStore/wiki/Getting-Started
#
# NOTE: All inputs are defined by external environment variables.
#       Optional variables have reasonable defaults, but you may override as needed.
#       Script should be run with installed user privilege (i.e. 'non-root' user).
#       Script is normally invoked via a chron job. For more information, see:
#         - /opt/fso-lab-devops/provisioners/scripts/aws/install_aws_teastore_order_processor_cron_job.sh
#         - /etc/cron.d/restart-teastore-order-processor
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] teastore application deploy/undeploy parameters [w/ defaults].
eks_kubeconfig_filepath="${eks_kubeconfig_filepath:-${HOME}/.kube/config}"
max_restart_count="${max_restart_count:-100}"
kubectl_pause_time="${kubectl_pause_time:-10}"

# create log file. ---------------------------------------------------------------------------------
logfile="$HOME/environment/workshop/order-processor-cron-job.log"
curtime=$(date +"%Y-%m-%d.%I:%M:%S.%p.%Z")

mkdir -p $HOME/environment/workshop/
touch $logfile

# validate kubernetes config files. ----------------------------------------------------------------
# test if eks kubeconfig file exists.
if [ ! -f "$eks_kubeconfig_filepath" ]; then
  echo "${curtime}: Notice: EKS kubeconfig file '${eks_kubeconfig_filepath}' does NOT exist." >> $logfile
  exit 0
fi

# validate the teastore application project. -------------------------------------------------------
# test if teastore application project directory exists.
if [ ! -d "${HOME}/TeaStore/examples/fso-hybrid" ]; then
  echo "${curtime}: Notice: TeaStore GitHub repository folder '${HOME}/TeaStore/examples/fso-hybrid' does NOT exist." >> $logfile
  exit 0
fi

# retrieve number of restarts for the order processor service. -------------------------------------
echo "${curtime}: kubectl get pods --kubeconfig ${eks_kubeconfig_filepath} | awk '/teastore-orderprocessor/ {print \$4}'" >> $logfile
orderprocessor_restarts=$(kubectl get pods --kubeconfig ${eks_kubeconfig_filepath} | awk '/teastore-orderprocessor/ {print $4}')

if [ -z "$orderprocessor_restarts" ]; then
  echo "${curtime}: Notice: Order Processor serivce is NOT deployed." >> $logfile
  exit 0
fi

echo "${curtime}: Order Processor restarts: ${orderprocessor_restarts}" >> $logfile

# check number of restarts. ---------------------------------------------------------------------
if [ "$orderprocessor_restarts" -le "$max_restart_count" ]; then
  echo "${curtime}: Notice: Order Processor restarts have not reached 'max_restart_count' of: ${max_restart_count}" >> $logfile
  exit 0
fi

# undeploy the teastore application from a hybrid kubernetes environment. --------------------------
echo "${curtime}: cd $HOME/TeaStore/examples/fso-hybrid/" >> $logfile
cd $HOME/TeaStore/examples/fso-hybrid/

# undeploy the teastore order processor service from aws eks.
echo "${curtime}: Undeploying the TeaStore Order Processor Service from AWS EKS cluster..." >> $logfile
echo "${curtime}: kubectl delete -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}" >> $logfile
kubectl delete -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}

# remove the teastore order processor service generated yaml file.
echo "${curtime}: Deleting the TeaStore Order Processor service generated YAML files..." >> $logfile
echo "${curtime}: rm -f teastore-orderprocessor.yaml" >> $logfile
rm -f teastore-orderprocessor.yaml

# allow time for the teastore order processor service to be undeployed.
echo "${curtime}: Pausing for ${kubectl_pause_time} seconds..." >> $logfile
sleep ${kubectl_pause_time}

# deploy the teastore order processor service to aws eks. -----------------------------------------
echo "${curtime}: Deploying the TeaStore Order Processor service to AWS EKS cluster..." >> $logfile

# store teastore registry nodeport host.
export REGISTRY_NODEPORT_HOST=$(kubectl get nodes -o wide --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.items[1].status.addresses[0].address')
echo "${curtime}: REGISTRY_NODEPORT_HOST: ${REGISTRY_NODEPORT_HOST}" >> $logfile

# store teastore registry nodeport port.
export REGISTRY_NODEPORT_PORT=$(kubectl get services teastore-registry --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.spec.ports[0].nodePort')
echo "${curtime}: REGISTRY_NODEPORT_PORT: ${REGISTRY_NODEPORT_PORT}" >> $logfile

# substitute environment variables for the teastore registry host and port.
echo "${curtime}: envsubst < teastore-orderprocessor.yaml.template > teastore-orderprocessor.yaml" >> $logfile
envsubst < teastore-orderprocessor.yaml.template > teastore-orderprocessor.yaml

# deploy the teastore order processor service.
echo "${curtime}: kubectl apply -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}" >> $logfile
kubectl apply -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}

# print completion message. ------------------------------------------------------------------------
echo "${curtime}: Order Processor service redeployment complete." >> $logfile

# delete log file after 20,000 lines. --------------------------------------------------------------
logfile_lines=$(cat $logfile | wc -l)
if [ "$logfile_lines" -gt 20000 ]; then
  rm -f $logfile
fi
