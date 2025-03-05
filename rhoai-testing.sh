#!/bin/bash
set -euo pipefail

export RHOAI_VERSION=${RHOAI_VERSION:=4.18}
export RHOAI_IMAGE=${RHOAI_IMAGE:="quay.io/rhoai/rhoai-fbc-fragment:rhoai-$RHOAI_VERSION-nightly"}
export CHANNEL=${CHANNEL:=fast}
export VLLM_IMAGE=${VLLM_IMAGE:="quay.io/aaruniaggarwal/vllm:vllm-oblas-rhel-tar"}
export WORKSPACE=/root
export PROJECT=${PROJECT:=raw-deployment}

if [ ! -e /usr/local/bin/oc ]; then
        echo " oc cli should be installed ."
        exit 1
fi

if ! oc get secret/pull-secret -n openshift-config -o json | \
       jq -r '.data.".dockerconfigjson"' | base64 -d | grep -q quay.io/rhoai; then
  echo "Please update OCP pull-secret with quay.io/rhoai auth"
  exit 1
fi

if [ ! -e $WORKSPACE/olminstall ]; then
        echo " olminstall repository is required for creating RHOAI Subscription."
        exit 1
fi

echo "Create ImagecontentSourcePolicy"
curl -LO https://github.com/red-hat-data-services/setup-rhoai/raw/konflux/konflux/imagepolicy.yaml
oc create -f imagepolicy.yaml

## Clone setup-rhoai repository

#echo -e "\n Cloning setup-rhoai repository and create imagecontentsourcepolicy"

#git clone -b konflux --single-branch https://github.com/red-hat-data-services/setup-rhoai.git && cd setup-rhoai/

#oc create -f konflux/imagepolicy.yaml

#sed -i 's|quay.io/rhoai/rhoai-fbc-fragment:rhoai-2.16@sha256:bc9b09e5a70c03d92c7234fe207f957d09392a0c915e5ec5bb9b41f08505ff97|'$RHOAI_IMAGE'|g' konflux/catalogsource.yaml

#echo -e "\n Executing setup_rhoai.sh script"

#./setup_rhoai.sh 2>&1 | tee $WORKSPACE/setup-rhoai.log

echo -e "\n Go to olminstall repository for creating Subscription"

cd $WORKSPACE/olminstall

./setup.sh -t operator -i $RHOAI_IMAGE -u $CHANNEL 

echo -e "\n Check CSV and Subscription"
sleep 1m
oc get subscription,csv,pods -n redhat-ods-operator

echo -e "\n KSERVE RAW DEPLOYMENT"

echo -e "\n Creating DSCInitialization"
oc create -f $WORKSPACE/rhoai-installation/DSCInitialization.yaml
sleep 2m

echo -e "\n Creating Data Science Cluster"
oc create -f $WORKSPACE/rhoai-installation/DataScienceCluster.yaml
sleep 2m

echo -e "\n Confirm all pods in redhat-ods-applications namespace are up and running"
oc get pods -n redhat-ods-applications | grep -q -v "Completed\|Running"

if [ $? != 0 ]
then
      echo -e "\n Pods in redhat-ods-applications namespace are in Error state.."
      exit 1
fi

echo -e "\n Creating new project for inferencing"
oc new-project $PROJECT

echo -e "\n Creating secret to store s3 bucket credentials"
sed -i "s|ACCESS_ID|$AWS_ACCESS_KEY|g" $WORKSPACE/rhoai-installation/isvc-secret.yaml
sed -i "s|SECRET_KEY|$AWS_SECRET_KEY|g" $WORKSPACE/rhoai-installation/isvc-secret.yaml
oc create -f $WORKSPACE/rhoai-installation/isvc-secret.yaml

echo -e "\n Creating a service account to bind to above created secret..."
oc create -f $WORKSPACE/rhoai-installation/isvc-sa.yaml

echo -e "\n Creating Serving Runtime"
sed -i "s|PLACEHOLDER|$VLLM_IMAGE|g" $WORKSPACE/rhoai-installation/servingRuntime.yaml
oc create -f $WORKSPACE/rhoai-installation/servingRuntime.yaml

echo -e "\n Create Inference Service"
oc create -f $WORKSPACE/rhoai-installation/inferenceService.yaml
