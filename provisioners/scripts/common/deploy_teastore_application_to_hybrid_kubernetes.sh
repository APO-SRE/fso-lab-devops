#!/bin/sh -eu
#---------------------------------------------------------------------------------------------------
# Deploy FSO-customized TeaStore microservice application to hybrid Kubernetes (EKS/IKS).
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
# [MANDATORY] teastore application deploy parameters [w/ defaults].
iks_kubeconfig_filepath="${iks_kubeconfig_filepath:-}"

# [OPTIONAL] teastore application deploy parameters [w/ defaults].
eks_kubeconfig_filepath="${eks_kubeconfig_filepath:-${HOME}/.kube/config}"
kubectl_pause_time="${kubectl_pause_time:-90}"

# define usage function. ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:
  Deploy FSO-customized TeaStore microservice application to hybrid Kubernetes (EKS/IKS).

  NOTE: All inputs are defined by external environment variables.
        Optional variables have reasonable defaults, but you may override as needed.
        Script should be run with installed user privilege (i.e. 'non-root' user).

  [MANDATORY] teastore application deploy parameters [w/ defaults].
    [ec2-user]$ export iks_kubeconfig_filepath="\$HOME/FSO-SRE-kubeconfig.yml"    # IKS kubeconfig file path.

  [OPTIONAL] teastore application deploy parameters [w/ defaults].
    [ec2-user]$ export eks_kubeconfig_filepath="\$HOME/.kube/config"              # [optional] EKS kubeconfig file (defaults to '\$HOME/.kube/config').
    [ec2-user]$ export kubectl_pause_time="90"                                   # [optional] 'kubectl' pause time to allow deployments to complete. (defaults to '90').

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
# test if eks kubeconfig file exists.
if [ ! -f "$eks_kubeconfig_filepath" ]; then
  echo "Error: EKS kubeconfig file '${eks_kubeconfig_filepath}' does NOT exist."
  usage
  exit 1
fi

# test if iks kubeconfig file exists.
if [ ! -f "$iks_kubeconfig_filepath" ]; then
  echo "Error: IKS kubeconfig file '${iks_kubeconfig_filepath}' does NOT exist."
  usage
  exit 1
fi

# import teastore application project from github.com. ---------------------------------------------
# change directory to lab user's home directory.
cd $HOME

# download teastore application project from github.com.
echo "Downloading TeaStore application project from GitHub.com..."
rm -Rf ./TeaStore
git clone https://github.com/brownkw/TeaStore.git
cd $HOME/TeaStore
git fetch origin
echo ""

# deploy the teastore application to a hybrid kubernetes environment. ------------------------------
cd $HOME/TeaStore/examples/k8s-split/

# deploy the teastore registry service to aws eks.
echo "Deploying the TeaStore Registry service to AWS EKS cluster..."
kubectl apply -f ./teastore-registry.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# allow time for the services to be deployed and then validate deployment.
echo "kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "kubectl get services --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get services --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# store teastore registry nodeport host.
export REGISTRY_NODEPORT_HOST=$(kubectl get nodes -o wide --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.items[0].status.addresses[0].address')
echo "REGISTRY_NODEPORT_HOST: ${REGISTRY_NODEPORT_HOST}"

# store teastore registry nodeport port.
export REGISTRY_NODEPORT_PORT=$(kubectl get services teastore-registry --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.spec.ports[0].nodePort')
echo "REGISTRY_NODEPORT_PORT: ${REGISTRY_NODEPORT_PORT}"
echo ""

# deploy the teastore persistence service to intersight iks.
cp -p teastore-persistence.yaml teastore-persistence.yaml.orig
envsubst < teastore-persistence.yaml > teastore-persistence.yaml.lb
mv teastore-persistence.yaml.lb teastore-persistence.yaml

echo "Deploying the TeaStore Persistence services to Intersight IKS cluster..."
kubectl apply -f teastore-persistence.yaml --kubeconfig ${iks_kubeconfig_filepath}
echo ""

echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# allow time for the services to be deployed and then validate deployment.
echo "kubectl get pods -o wide --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get pods -o wide --kubeconfig ${iks_kubeconfig_filepath}
echo ""

echo "kubectl get services --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get services --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# store teastore persistence nodeport host.
export PERSISTENCE_NODEPORT_HOST=$(kubectl get nodes -o wide --output json --kubeconfig ${iks_kubeconfig_filepath} | jq -r '.items[1].status.addresses[1].address')
echo "PERSISTENCE_NODEPORT_HOST: ${PERSISTENCE_NODEPORT_HOST}"

# store teastore persistence nodeport port.
export PERSISTENCE_NODEPORT_PORT=$(kubectl get services teastore-persistence --output json --kubeconfig ${iks_kubeconfig_filepath} | jq -r '.spec.ports[0].nodePort')
echo "PERSISTENCE_NODEPORT_PORT: ${PERSISTENCE_NODEPORT_PORT}"
echo ""

# store the teastore persistence nodeport environment variables to intersight iks deployment.
echo "Storing the TeaStore Persistence NodePort environment variables to the IKS deployment..."
echo "kubectl set env deployment/teastore-persistence HOST_NAME=$PERSISTENCE_NODEPORT_HOST --kubeconfig ${iks_kubeconfig_filepath}"
kubectl set env deployment/teastore-persistence HOST_NAME=$PERSISTENCE_NODEPORT_HOST --kubeconfig ${iks_kubeconfig_filepath}
echo "kubectl set env deployment/teastore-persistence SERVICE_PORT=$PERSISTENCE_NODEPORT_PORT --kubeconfig ${iks_kubeconfig_filepath}"
kubectl set env deployment/teastore-persistence SERVICE_PORT=$PERSISTENCE_NODEPORT_PORT --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# deploy the teastore frontend services to aws eks.
echo "Deploying the TeaStore Front-End services to AWS EKS cluster..."
kubectl apply -f ./teastore-frontend.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "Pausing for $(($kubectl_pause_time * 2)) seconds..."
sleep $(($kubectl_pause_time * 2))
echo ""

# allow time for the services to be deployed and then validate deployment.
echo "kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "kubectl get services --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get services --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# create and display the teastore application url.
export WEBUI_LOADBALANCER_HOST=$(kubectl get services teastore-webui --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.status.loadBalancer.ingress[0].hostname')
export TEASTORE_URL="http://${WEBUI_LOADBALANCER_HOST}:8080/tools.descartes.teastore.webui/"
echo "TEASTORE_URL: ${TEASTORE_URL}"
echo ""

# validate the application deployment.
#curl --silent $TEASTORE_URL | grep 'title'
#echo ""

# print completion message. ------------------------------------------------------------------------
echo "Please wait ~5 minutes for the AWS Load Balancer to be deployed and complete its health checks."
echo "TeaStore hybrid deployment complete."
