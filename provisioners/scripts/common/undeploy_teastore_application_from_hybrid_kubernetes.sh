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
kubectl_pause_time="${kubectl_pause_time:-90}"

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
    [ec2-user]$ export kubectl_pause_time="90"                                   # [optional] 'kubectl' pause time to allow undeployments to complete. (defaults to '90').

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
if [ ! -d "${HOME}/TeaStore" ]; then
  echo "Error: TeaStore GitHub repository folder '${HOME}/TeaStore' does NOT exist."
  usage
  exit 1
fi

# undeploy the teastore application from a hybrid kubernetes environment. --------------------------
cd $HOME/TeaStore/examples/k8s-split/

# undeploy the teastore frontend services from aws eks.
echo "Undeploying the TeaStore Front-End services from AWS EKS cluster..."
kubectl delete -f ./teastore-frontend.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "Pausing for $(($kubectl_pause_time * 2)) seconds..."
sleep $(($kubectl_pause_time * 2))
echo ""

# undeploy the teastore persistence service from intersight iks.
echo "Undeploying the TeaStore Persistence services from Intersight IKS cluster..."
kubectl delete -f teastore-persistence.yaml --kubeconfig ${iks_kubeconfig_filepath}
echo ""

echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# undeploy the teastore registry service from aws eks.
echo "Undeploying the TeaStore Registry services from AWS EKS cluster..."
kubectl delete -f ./teastore-registry.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# remove the teastore application project directory. -----------------------------------------------
echo "Deleting the TeaStore application project directory..."
rm -Rf $HOME/TeaStore
echo ""

# validate the teastore services undeployment. -----------------------------------------------------
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
