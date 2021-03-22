# Microsoft Azure Integrations

Showcase the integrations to Microsoft Azure built in SCONE platform.

## Summary

In this sample, a Flask REST API (built with SCONE) running on a Confidential Azure Kubernetes Service cluster is attested by a Microsoft Azure Attestation provider, allowing secrets stored in an Azure Key Vault instance and in the SCONE CAS (Configuration and Attestation Service) to be securely delivered to the attested enclave instance.

## Demo

### Screencast

[![SCONE Platform: Azure integrations](http://img.youtube.com/vi/S8nnXNWV9zw/0.jpg)](http://www.youtube.com/watch?v=S8nnXNWV9zw)

### Prerequisites

To run this tutorial, you need an Azure subscription and the following resources:

#### Register an application to Azure Active Directory

To fetch tokens, you must provide the `Application (client) ID`, the `Directory (tenant) ID` and the credentials (`Client secret`) of your application. Please note that credentials can be either client secrets or certificates, and the SCONE platform supports both. For the sake of this demo, however, we are assuming a client secret.

Please refer to the official Azure documentation to see [how to register applications and create client secrets](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app).

Finally, export the credentials to the environment:

```bash
export AZURE_TENANT_ID="..."
export AZURE_CLIENT_ID="..."
export AZURE_CLIENT_SECRET="..."
```

#### Create an Azure Key Vault instance

Please refer to the official Azure documentation to see [how to create an Azure Key Vault instance](https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-portal). This tutorial assumes that the AKV has to secrets:

- A secret: a string of your choice. The content of this secret will be retrieved via the REST API at the end. In this example, we're using `a13f688c788626380ae1209e31e664891fc19dcdd0cfa29c27ca7e6e16b83a95`.
- A certificate. This certificate, as well as its private key, will be used by our REST API when setting up an HTTPS server. Set up the certificate _Common Name_ to `CN=rest-api.scone.sample`. Please note that the certificate can either be signed by one of the integrated authorities or be self-signed.

Export the name of such secrets to the environment, as well as the AKV URL, _e.g._:

```bash
export AKV_VAULT="https://scone-sample.vault.azure.net/"
export AKV_SECRET_NAME="sample-secret"
export AKV_CERT_SECRET_NAME="flask"
```

Finally, refer to the official Azure documentation to [give AKV access the application you created in the previous example](https://docs.microsoft.com/en-us/azure/key-vault/general/assign-access-policy-portal).

#### Create Microsoft Azure Attestation provider

This step is required only if you want to explore custom policies. Please refer to the official Azure documentation to see [how to create an MAA instance](https://docs.microsoft.com/en-us/azure/attestation/quickstart-portal) and [submit custom policies](https://docs.microsoft.com/en-us/azure/attestation/author-sign-policy).

If you are not interested in custom policies, you can rely on one of the shared MAA instances provided by Microsoft, _e.g._:

```bash
export MAA_PROVIDER="https://sharedcus.cus.attest.azure.net"
```

#### Create a Confidential Azure Kubernetes Service cluster

This step is required only if you want to run the demo in a Kubernetes cluster using the included Helm charts. Please refer to the official Azure documentation to see [how to create a confidential AKS cluster](https://docs.microsoft.com/en-us/azure/confidential-computing/confidential-nodes-aks-overview).

If you are not interested in Kubernetes, you can rely on the included docker-compose manifests in `deploy/compose`. Please note that you must run the demo in an [Azure Confidential Computing VM](https://docs.microsoft.com/en-us/azure/confidential-computing/confidential-computing-enclaves), otherwise MAA won't attest your enclaves.

### Running

#### Setup

Export the appropriate image names and SGX device:

```bash
source environment
```

Install SCONE Attestation Services: CAS and LAS. We expose CAS to the internet through an Azure Load Balancer and an external IP address (`--set service.type=LoadBalancer`). If you want to specify a specific static IP address, you have to create it in the appropriate resource group and add `--set service.loadBalancerIP=$STATIC_IP`. Please refer to the Azure documentation to see [how to create static IP addresses to use with AKS](https://docs.microsoft.com/en-us/azure/aks/static-ip).

Please also note that the services rely on the SGX Device Plugin (`--set useSGXDevPlugin=azure`) and AESM (`--set externalAesmd.enabled=true`) provided by Azure.

```bash
helm install cas deploy/helm/cas \
   --set service.type=LoadBalancer \
   --set useSGXDevPlugin=azure


helm install las deploy/helm/las \
   --set useSGXDevPlugin=azure
```

#### Submit policies

First, retrieve the CAS public IP (please note that it may take a while until the IP is available):

```bash
export SCONE_CAS_ADDR=$(kubectl get svc cas --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
```

Specify the name of the CAS namespace and of the session we are going to create.

```bash
export CAS_NAMESPACE=azure-integration-$RANDOM$RANDOM$RANDOM
export PYTHON_SESSION_NAME=demo
```

Start a local SCONE CLI container to submit policies to our CAS. Pass the environment variables to the local container, so the CLI can use them to populate the session template (`session.template.yml`):

```bash
docker run -d --rm --network host \
   -v $PWD:/templates \
   -e SCONE_CAS_ADDR=$SCONE_CAS_ADDR \
   -e CAS_NAMESPACE=$CAS_NAMESPACE \
   -e PYTHON_SESSION_NAME=$PYTHON_SESSION_NAME \
   -e AZURE_TENANT_ID=$AZURE_TENANT_ID \
   -e AZURE_CLIENT_ID=$AZURE_CLIENT_ID \
   -e AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET \
   -e AKV_VAULT=$AKV_VAULT \
   -e AKV_SECRET_NAME=$AKV_SECRET_NAME \
   -e AKV_CERT_SECRET_NAME=$AKV_CERT_SECRET_NAME \
   -e MAA_PROVIDER=$MAA_PROVIDER \
   --name scone-cli \
   --entrypoint sh \
   $CLI_IMAGE \
   -c "sleep 7200"
docker exec -it scone-cli bash
```

Inside of the CLI container, run:

```bash
./templates/attest-cas.sh
```

Create a CAS namespace:

```bash
scone session create --use-env /templates/namespace.template.yml
```

Submit the templates by running the following command. The option `--use-env` will allow the CLI to use the environment to replace variables inside of the session template.

```bash
scone session create --use-env /templates/session.template.yml
```

#### Start application

Run the application without attestation: the application will crash because there are no certificates in the expected locations.

```bash
helm install api-no-attestation deploy/helm/rest-api-sample \
   --set service.type=LoadBalancer \
   --set useSGXDevPlugin=azure
```

Now, run the application with attestation. The REST API should start once it gets attested and the appropriate secret and certificates—retrieved from AKV—are transparently and securely injected into the enclave's filesystem and environment.

```bash
export SCONE_CONFIG_ID=$CAS_NAMESPACE/$PYTHON_SESSION_NAME/rest-api
helm install api deploy/helm/rest-api-sample \
   --set service.type=LoadBalancer \
   --set useSGXDevPlugin=azure \
   --set scone.cas=$SCONE_CAS_ADDR \
   --set scone.configId=$SCONE_CONFIG_ID
```

Retrieve the public IP address for our REST API:

```bash
export API_ADDR=$(kubectl get svc api-rest-api-sample --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
```

Access the REST API using cURL. Please note that you must use the _Common Name_ as specified in the certificate that you created in AKV.

```bash
curl https://rest-api.scone.sample:4996/secret --resolve rest-api.scone.sample:4996:$API_ADDR
```

> If you created a self-signed certificate in AKV, you need to pass `-k` flag to cURL.

The expected output looks like:

```json
{"access_timestamp":1615855461.7656054,"secret":"a13f688c788626380ae1209e31e664891fc19dcdd0cfa29c27ca7e6e16b83a95"}
```

### Clean up

Remove resources deployed to the Kubernetes cluster, as well the SCONE CLI container. Finally, unset the Azure credentials from the environment:

```bash
helm delete cas las api-no-attestation api
docker stop scone-cli
unset AZURE_TENANT_ID AZURE_CLIENT_ID AZURE_CLIENT_SECRET
```

Use the Azure Portal or the Azure CLI to clean up the resources created on Azure, such the as AKS cluster or the Azure Key Vault. Please refer to the official Azure documentation to see [how to open and delete resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resources-portal#delete-resources).

### Limitations

- Some MAA instances run inside of enclaves. We currently do not support attestation of the MAA instance itself.

- Currently, secrets are injected only during the startup of the enclave. Since the tokens will expire eventually (AAD tokens have a maximum duration of 24 hours), the enclave has to restart and reattest itself in order to get a new token.
