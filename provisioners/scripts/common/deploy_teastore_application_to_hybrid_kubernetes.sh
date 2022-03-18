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
kubectl_pause_time="${kubectl_pause_time:-10}"

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
    [ec2-user]$ export kubectl_pause_time="10"                                    # [optional] 'kubectl' pause time to allow deployments to complete. (defaults to '10').

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

# add labels to kubernetes worker nodes for manual balancing of pod workloads. ---------------------
echo "----------------------------------------------------------------------------------------------------"
echo "Adding labels to Kubernetes worker nodes..."

# add labels to aws eks cluster. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
eks_node_1=$(kubectl get nodes -o wide --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.items[0].metadata.name')
eks_node_2=$(kubectl get nodes -o wide --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.items[1].metadata.name')

echo "kubectl label --overwrite nodes ${eks_node_1} eksWorkerNode=eks-worker-node-01 --kubeconfig ${eks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${eks_node_1} eksWorkerNode=eks-worker-node-01 --kubeconfig ${eks_kubeconfig_filepath}
echo "kubectl label --overwrite nodes ${eks_node_2} eksWorkerNode=eks-worker-node-02 --kubeconfig ${eks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${eks_node_2} eksWorkerNode=eks-worker-node-02 --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "kubectl get nodes --show-labels --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get nodes --show-labels --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# add labels to intersight iks cluster. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
iks_node_1=$(kubectl get nodes -o wide --output json --kubeconfig ${iks_kubeconfig_filepath} | jq -r '.items[1].metadata.name')
iks_node_2=$(kubectl get nodes -o wide --output json --kubeconfig ${iks_kubeconfig_filepath} | jq -r '.items[2].metadata.name')

echo "kubectl label --overwrite nodes ${iks_node_1} iksWorkerNode=iks-worker-node-01 --kubeconfig ${iks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${iks_node_1} iksWorkerNode=iks-worker-node-01 --kubeconfig ${iks_kubeconfig_filepath}
echo "kubectl label --overwrite nodes ${iks_node_2} iksWorkerNode=iks-worker-node-02 --kubeconfig ${iks_kubeconfig_filepath}"
kubectl label --overwrite nodes ${iks_node_2} iksWorkerNode=iks-worker-node-02 --kubeconfig ${iks_kubeconfig_filepath}
echo ""

echo "kubectl get nodes --show-labels --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get nodes --show-labels --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# deploy the teastore application to a hybrid kubernetes environment. ------------------------------
echo "cd $HOME/TeaStore/examples/fso-hybrid/"
cd $HOME/TeaStore/examples/fso-hybrid/

# deploy the teastore database to intersight iks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Database to Intersight IKS cluster..."
echo "kubectl apply -f ./teastore-db.yaml --kubeconfig ${iks_kubeconfig_filepath}"
kubectl apply -f ./teastore-db.yaml --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# deploy the teastore registry service to aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Registry service to AWS EKS cluster..."
echo "kubectl apply -f ./teastore-registry.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl apply -f ./teastore-registry.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the teastore registry service to be deployed.
echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# store teastore registry nodeport host.
export REGISTRY_NODEPORT_HOST=$(kubectl get nodes -o wide --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.items[1].status.addresses[0].address')
echo "REGISTRY_NODEPORT_HOST: ${REGISTRY_NODEPORT_HOST}"

# store teastore registry nodeport port.
export REGISTRY_NODEPORT_PORT=$(kubectl get services teastore-registry --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.spec.ports[0].nodePort')
echo "REGISTRY_NODEPORT_PORT: ${REGISTRY_NODEPORT_PORT}"
echo ""

# store the teastore registry nodeport environment variables to aws eks deployment.
echo "Storing the TeaStore Registry NodePort environment variables to the EKS deployment..."
echo "kubectl set env deployment/teastore-registry HOST_NAME=$REGISTRY_NODEPORT_HOST --kubeconfig ${eks_kubeconfig_filepath}"
kubectl set env deployment/teastore-registry HOST_NAME=$REGISTRY_NODEPORT_HOST --kubeconfig ${eks_kubeconfig_filepath}
echo "kubectl set env deployment/teastore-registry SERVICE_PORT=$REGISTRY_NODEPORT_PORT --kubeconfig ${eks_kubeconfig_filepath}"
kubectl set env deployment/teastore-registry SERVICE_PORT=$REGISTRY_NODEPORT_PORT --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the teastore registry service to be deployed.
echo "Pausing for $(($kubectl_pause_time * 9)) seconds..."
sleep $(($kubectl_pause_time * 9))
echo ""

# deploy the teastore persistence service to intersight iks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Persistence service to Intersight IKS cluster..."

# substitute environment variables for the teastore registry host and port.
echo "envsubst < teastore-persistence.yaml.template > teastore-persistence.yaml"
envsubst < teastore-persistence.yaml.template > teastore-persistence.yaml

# deploy the teastore persistence service.
echo "kubectl apply -f teastore-persistence.yaml --kubeconfig ${iks_kubeconfig_filepath}"
kubectl apply -f teastore-persistence.yaml --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# allow time for the teastore persistence service to be deployed.
echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# store teastore persistence nodeport host.
export PERSISTENCE_NODEPORT_HOST=$(kubectl get nodes -o wide --output json --kubeconfig ${iks_kubeconfig_filepath} | jq -r '.items[2].status.addresses[1].address')
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

# allow time for the teastore persistence service to be deployed.
echo "Pausing for $(($kubectl_pause_time * 9)) seconds..."
sleep $(($kubectl_pause_time * 9))
echo ""

# deploy the teastore auth service to aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Auth service to AWS EKS cluster..."

# substitute environment variables for the teastore registry host and port.
echo "envsubst < teastore-auth.yaml.template > teastore-auth.yaml"
envsubst < teastore-auth.yaml.template > teastore-auth.yaml

# deploy the teastore auth service.
echo "kubectl apply -f ./teastore-auth.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl apply -f ./teastore-auth.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# deploy the teastore webui service to aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore WebUI service to AWS EKS cluster..."

# substitute environment variables for the teastore registry host and port.
echo "envsubst < teastore-webui.yaml.template > teastore-webui.yaml"
envsubst < teastore-webui.yaml.template > teastore-webui.yaml

# deploy the teastore webui service.
echo "kubectl apply -f ./teastore-webui.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl apply -f ./teastore-webui.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the teastore webui service to be deployed.
echo "Pausing for $(($kubectl_pause_time * 18)) seconds..."
sleep $(($kubectl_pause_time * 18))
echo ""

# store teastore webui load balancer host.
export WEBUI_LOADBALANCER_HOST=$(kubectl get services teastore-webui --output json --kubeconfig ${eks_kubeconfig_filepath} | jq -r '.status.loadBalancer.ingress[0].hostname')

# deploy the teastore recommender service to aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Recommender service to AWS EKS cluster..."
echo ""

# substitute environment variables for the teastore registry host and port.
echo "envsubst < teastore-recommender.yaml.template > teastore-recommender.yaml"
envsubst < teastore-recommender.yaml.template > teastore-recommender.yaml

# deploy the teastore recommender service.
echo "kubectl apply -f ./teastore-recommender.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl apply -f ./teastore-recommender.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# deploy the teastore image service to aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Image service to AWS EKS cluster..."

# substitute environment variables for the teastore registry host and port.
echo "envsubst < teastore-image.yaml.template > teastore-image.yaml"
envsubst < teastore-image.yaml.template > teastore-image.yaml

# deploy the teastore image service.
echo "kubectl apply -f ./teastore-image.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl apply -f ./teastore-image.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the teastore image service to be deployed.
echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# deploy the teastore order processing service to aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Order Processing service to AWS EKS cluster..."

# substitute environment variables for the teastore registry host and port.
echo "envsubst < teastore-orderprocessor.yaml.template > teastore-orderprocessor.yaml"
envsubst < teastore-orderprocessor.yaml.template > teastore-orderprocessor.yaml

# deploy the teastore order processing service.
echo "kubectl apply -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl apply -f ./teastore-orderprocessor.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the teastore order processing service to be deployed.
echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# deploy the teastore load generator to aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Deploying the TeaStore Load Generator to AWS EKS cluster..."

# deploy the teastore load generator.
echo "kubectl apply -f ./teastore-loadgen.yaml --kubeconfig ${eks_kubeconfig_filepath}"
kubectl apply -f ./teastore-loadgen.yaml --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# allow time for the teastore load generator to be deployed.
echo "Pausing for ${kubectl_pause_time} seconds..."
sleep ${kubectl_pause_time}
echo ""

# validate deployment of the teastore services. ----------------------------------------------------
# validate deployment of the teastore front-end services on aws eks. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo "----------------------------------------------------------------------------------------------------"
echo "Validating the AWS EKS environment..."
echo "kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get pods -o wide --kubeconfig ${eks_kubeconfig_filepath}
echo ""

echo "kubectl get services --kubeconfig ${eks_kubeconfig_filepath}"
kubectl get services --kubeconfig ${eks_kubeconfig_filepath}
echo ""

# validate deployment of the teastore persistence services on intersight iks. ^^^^^^^^^^^^^^^^^^^^^^
echo "Validating the Intersight IKS environment..."
echo "kubectl get pods -o wide --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get pods -o wide --kubeconfig ${iks_kubeconfig_filepath}
echo ""

echo "kubectl get services --kubeconfig ${iks_kubeconfig_filepath}"
kubectl get services --kubeconfig ${iks_kubeconfig_filepath}
echo ""

# create and display the teastore application url. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
export TEASTORE_URL="http://${WEBUI_LOADBALANCER_HOST}:8080/tools.descartes.teastore.webui/"
echo "TEASTORE_URL: ${TEASTORE_URL}"
echo ""

# validate the application deployment.
#curl --silent $TEASTORE_URL | grep 'title'
#echo ""

# print completion message. ------------------------------------------------------------------------
echo "Please wait ~5 minutes for the AWS Load Balancer to be deployed and complete its health checks."
echo "TeaStore hybrid deployment complete."
