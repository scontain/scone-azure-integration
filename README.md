**TODO**

- [x] Add source code of the REST API.
- [ ] Script for creating session + testing.
- [ ] Create Helm charts for demo.
- [ ] Squash images.
- [ ] Finish demo step-by-step.
- [ ] Record screencast.

# Microsoft Azure Integrations

Showcase the integrations to Microsoft Azure built in SCONE platform.

## Summary

In this sample, a Flask REST API (built with SCONE) running on a Confidential Azure Kubernetes Service cluster is attested by a Microsoft Azure Attestation provider, allowing secrets stored in an Azure Key Vault instance and in the SCONE CAS (Configuration and Attestation Service) to be securely delivered to the attested enclave instance.

### Screencast

TODO.

## Demo

TODO.

```bash
export CAS_IMAGE=registry.scontain.com:5050/clenimar/azure-integration-demo:cas.preprovisioned-scone5.2.1
export LAS_IMAGE=registry.scontain.com:5050/clenimar/azure-integration-demo:las-scone5.2.1
export API_IMAGE=registry.scontain.com:5050/clenimar/azure-integration-demo:restapiv1-scone5.2.1
export PYTHON_IMAGE=registry.scontain.com:5050/clenimar/azure-integration-demo:python3.7-scone5.2.1
export REDIS_IMAGE=registry.scontain.com:5050/clenimar/azure-integration-demo:redis6-scone5.2.1
export CLI_IMAGE=registry.scontain.com:5050/clenimar/azure-integration-demo:sconecli-scone5.2.1
```

### Before:

1. Create a Confidential AKS cluster.
2. Export any needed application credentials to the environment.
3. Create an AKV instance. Create secrets (cert, key and string)
4. Create an MAA provider and submit a custom policy to it.

### During/Setup:

1. Deploy SCONE Services using Helm: CAS and LAS. LAS uses the external AESM provided by Azure.
2. On Azure Portal, create the secrets we're going to import later on: one string, one certificate and one private key.
3. Go through the session template, explain scenarios.

### Scenario 1: successful flow

1. Submit and retrieve scenario 1. Show that app is able to get the certificate and the key to serve HTTPS. Talk about injection and conversions.

### Scenario 2: attestation failure

1. Show custom policy.
2. Submit and retrieve scenario 2. Expect an attestation error from MAA. Note: alternative would be to run somewhere else to trigger an MAA attestation failure.

### Limitations

* Some MAA instances run inside of enclaves. We currently do not support attestation the MAA instance itself.
* AAD tokens have a maximum expiration time of 24 hours. We currently do not support the renewal of AAD tokens at runtime. They are renewed upon every enclave startup only.
