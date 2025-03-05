<h2>Installing Openshift AI using RH builds</h2>

### Pre-requisites
- Make sure oc cli is installed in your cluster
- Clone [olminstall](https://gitlab.cee.redhat.com/data-hub/olminstall/) repository  in your WORKSPACE
- quay.io/rhoai secret should be there in the OCP cluster's pull secret. 
- Uninstall Openshift AI completely if it is installed

### Environment Variables

Make sure to export following variables before executing **rhoai-testing.sh** script.

Variable | Explanation
-------- | -------- 
RHOAI_IMAGE | RH Openshift AI build that needs to be deployed
CHANNEL  | RHOAI Subscription channel
VLLM_IMAGE   | vLLM image that will be used for inferencing
WORKSPACE | Directory where the rhoai-installation project is cloned. 
PROJECT   | Name of namespace where resouces like secret, serviceaccount , servingRuntime, ISVC should be created
AWS_ACCESS_KEY | AWS Access Key ID of s3 bucket where model is stored
AWS_SECRET_KEY | AWS Secret Access Key of s3 bucket where model is stored
