#!/bin/sh -eu
#---------------------------------------------------------------------------------------------------
# Undeploy FSO-customized TeaStore microservice application from hybrid Kubernetes (EKS/IKS).
#
# The TeaStore is a microservice reference and test application to be used in benchmarks and
# tests. The TeaStore emulates a basic web store for automatically generated tea and tea supplies.
# As it is primarily a test application, it features UI elements for database generation and
# service resetting in addition to the store itself.
#
# The TeaStore's persistence services use a MySQL/MariaDB database running in a container. The
# store automatically creates the required tables and resets them using the web UI. The following
# is a summary of the default database settings:
#
#   Default Host:      localhost
#   Default Port:      3306
#   Database name:     teadb
#   Database user:     teauser
#   Database password: teapassword
#
# For more details, please visit:
#   https://github.com/DescartesResearch/TeaStore
#   https://github.com/DescartesResearch/TeaStore/wiki/Getting-Started
#
# NOTE: All inputs are defined by external environment variables.
#       Optional variables have reasonable defaults, but you may override as needed.
#       Script should be run with installed user privilege (i.e. 'non-root' user).
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [MANDATORY] teastore application undeploy parameters [w/ defaults].
iks_kubeconfig_filepath="${iks_kubeconfig_filepath:-}"

# [OPTIONAL] teastore application undeploy parameters [w/ defaults].
eks_kubeconfig_filepath="${eks_kubeconfig_filepath:-${HOME}/.kube/config}"
kubectl_pause_time="${kubectl_pause_time:-10}"

# define usage function. ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:
  Undeploy FSO-customized TeaStore microservice application from hybrid Kubernetes (EKS/IKS).

  NOTE: All inputs are defined by external environment variables.
        Optional variables have reasonable defaults, but you may override as needed.
        Script should be run with installed user privilege (i.e. 'non-root' user).

  [MANDATORY] teastore application undeploy parameters [w/ defaults].
    [ec2-user]$ export iks_kubeconfig_filepath="${HOME}/FSO-SRE-kubeconfig.yml"  # IKS kubeconfig file path.

  [OPTIONAL] teastore application undeploy parameters [w/ defaults].
    [ec2-user]$ export eks_kubeconfig_filepath="${HOME}/.kube/config"            # [optional] EKS kubeconfig file (defaults to '${HOME}/.kube/config').
    [ec2-user]$ export kubectl_pause_time="10"                                   # [optional] 'kubectl' pause time to allow undeployments to complete. (defaults to '10').

    [ec2-user]$ $0
EOF
}

# validate environment variables. ------------------------------------------------------------------
if [ -z "$iks_kubeconfig_filepath" ]; then
  echo "Error: 'iks_kubeconfig_filepath' environment variable NOT set."
  usage
  exit 1
fi

# validate kubernetes config files. ----------------------------------------------------------------
# test if aws eks kubeconfig file exists.
if [ ! -f "$eks_kubeconfig_filepath" ]; then
  echo "Error: EKS kubeconfig file '${eks_kubeconfig_filepath}' does NOT exist."
  usage
  exit 1
fi

# test if intersight iks kubeconfig file exists.
if [ ! -f "$iks_kubeconfig_filepath" ]; then
  echo "Error: IKS kubeconfig file '${iks_kubeconfig_filepath}' does NOT exist."
  usage
  exit 1
fi

# validate the teastore application project. -------------------------------------------------------
# test if teastore application project directory exists.
if [ ! -d "${HOME}/TeaStore/examples/fso-hybrid" ]; then
  echo "Error: TeaStore GitHub repository folder '${HOME}/TeaStore/examples/fso-hybrid' does NOT exist."
  usage
  exit 1
fi

# undeploy the teastore application from a hybrid kubernetes environment. --------------------------
echo "cd $HOME/TeaStore/examples/fso-hybrid/"
cd $HOME/TeaStore/examples/fso-hybrid/

# undeploy the teastore load generator from aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Load Generator from AWS EKS cluster..."
echo "kubectl delete -f ./teastore-loadgen.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl delete -f ./teastore-loadgen.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# undeploy the teastore order processing service from aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Order Processing Service from AWS EKS cluster..."
echo "kubectl delete -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl delete -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# undeploy the teastore image service from aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Image service from AWS EKS cluster..."
echo "kubectl delete -f ./teastore-image.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl delete -f ./teastore-image.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# undeploy the teastore recommender service from aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Recommender service from AWS EKS cluster..."
echo "kubectl delete -f ./teastore-recommender.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl delete -f ./teastore-recommender.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# undeploy the teastore auth service from aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Auth service from AWS EKS cluster..."
echo "kubectl delete -f ./teastore-auth.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl delete -f ./teastore-auth.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# undeploy the teastore registry service from aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Registry service from AWS EKS cluster..."
echo "kubectl delete -f ./teastore-registry.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl delete -f ./teastore-registry.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# undeploy the teastore webui service from aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore WebUI service from AWS EKS cluster..."
echo "kubectl delete -f ./teastore-webui.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl delete -f ./teastore-webui.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the teastore front-end services to be undeployed. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "Pausing for $(($kubectl_pause_time * 18)) seconds..."
sleep $(($kubectl_pause_time * 18))
echo ""

# undeploy the teastore persistence service from intersight iks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Persistence service from Intersight IKS cluster..."
echo "kubectl delete -f teastore-persistence.yaml --kubeconfig ${iks_kubeconfig_filepath}"
kubectl delete -f teastore-persistence.yaml --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# undeploy the teastore database from intersight iks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Undeploying the TeaStore Database from Intersight IKS cluster..."
echo "kubectl delete -f teastore-db.yaml --kubeconfig ${iks_kubeconfig_filepath}"
kubectl delete -f teastore-db.yaml --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# allow time for the teastore front-end services to be undeployed. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "Pausing for $(($kubectl_pause_time * 9)) seconds..."
sleep $(($kubectl_pause_time * 9))
echo ""

# remove the teastore application generated yaml files. --------------------------------------------
echo "----------------------------------------------------------------------------------------------------"
echo "Deleting the TeaStore generated YAML files..."
echo "rm -f teastore-persistence.yaml teastore-auth.yaml teastore-webui.yaml teastore-recommender.yaml teastore-image.yaml teastore-orderprocessor.yaml"
rm -f teastore-persistence.yaml teastore-auth.yaml teastore-webui.yaml teastore-recommender.yaml teastore-image.yaml teastore-orderprocessor.yaml
echo ""

# remove labels from kubernetes worker nodes. ------------------------------------------------------
echo "----------------------------------------------------------------------------------------------------"
echo "Removing labels from Kubernetes worker nodes..."

# remove labels from aws eks cluster. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
eks_node_1=$(kubectl get nodes -o wide --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.items[0].metadata.name')
eks_node_2=$(kubectl get nodes -o wide --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.items[1].metadata.name')

echo "kubectl label --overwrite nodes ${eks_node_1} eksWorkerNode- --kubeconfig ${eks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${eks_node_1} eksWorkerNode- --kubeconfig ${eks_kubeconfig_filepath}
echo "kubectl label --overwrite nodes ${eks_node_2} eksWorkerNode- --kubeconfig ${eks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${eks_node_2} eksWorkerNode- --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "kubectl get nodes --show-labels --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get nodes --show-labels --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# remove labels from intersight iks cluster. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
iks_node_1=$(kubectl get nodes -o wide --output json --kubeconfig ${iks_kubeconfig_filepath} | jq -r '.items[1].metadata.name')
iks_node_2=$(kubectl get nodes -o wide --output json --kubeconfig ${iks_kubeconfig_filepath} | jq -r '.items[2].metadata.name')

echo "kubectl label --overwrite nodes ${iks_node_1} iksWorkerNode- --kubeconfig ${iks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${iks_node_1} iksWorkerNode- --kubeconfig ${iks_kubeconfig_filepath}
echo "kubectl label --overwrite nodes ${iks_node_2} iksWorkerNode- --kubeconfig ${iks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${iks_node_2} iksWorkerNode- --kubeconfig ${iks_kubeconfig_filepath}
echo ""

echo "kubectl get nodes --show-labels --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get nodes --show-labels --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# validate the teastore services undeployment. -----------------------------------------------------
echo "----------------------------------------------------------------------------------------------------"
echo "Validating the TeaStore services undeployment..."
echo ""

# allow time for the aws eks services to be undeployed and then validate.
echo "Checking the AWS EKS environment..."
echo "kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "kubectl get services --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get services --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the intersight iks services to be undeployed and then validate.
echo "Checking the Intersight IKS environment..."
echo "kubectl get pods -o wide --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get pods -o wide --kubeconfig ${iks_kubeconfig_filepath}
echo ""

echo "kubectl get services --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get services --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# print completion message. ------------------------------------------------------------------------
echo "TeaStore hybrid undeployment complete."
