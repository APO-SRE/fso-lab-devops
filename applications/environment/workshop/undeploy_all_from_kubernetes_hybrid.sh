#!/bin/bash


# undeploy the LoadGen for the application
kubectl delete -f /home/ec2-user/TeaStore/examples/fso-hybrid/teastore-loadgen.yaml

# undeploy the teastore application from both kubernetes clusters
/bin/bash /opt/fso-lab-devops/provisioners/scripts/common/undeploy_teastore_application_from_hybrid_kubernetes.sh


# undeploy appdynamics agents from both kubernetes clusters
./undeploy_appdynamics_db_agent_from_kubernetes.sh

./undeploy_appdynamics_agents_from_hybrid_kubernetes.sh
