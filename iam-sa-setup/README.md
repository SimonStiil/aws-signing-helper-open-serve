# Getting Started with IAM-RA

This description tries compile how to get started using IAM-RA.
I am codensing information from:
- [AWS IAM Roles Anywhere for Kubernetes - Self-managed CA Setup](https://github.com/aws-samples/aws-iam-ra-for-kubernetes/blob/main/cert-manager-self-managed-ca/README.md)
- [AWS RolesAnywhere Credential Helper](https://github.com/aws/rolesanywhere-credential-helper)
- [Setting up IAM Anywhere using Terraform (dev.to)](https://dev.to/gerson_morales_3e89188d50/setting-up-iam-anywhere-using-terraform-3nf)

## Root Trust anchor Certificate

First off we need to start with a Root certificate to use for this entire process.  

Generate Root certificate key  
```shell
openssl genrsa -out rootCAKey.pem 2048 
```

Modify `openssl.cnf` with the given content what fits with your organization. It does not require to be a valid domain.

Generate Root certificate (This may result in error emails with expiring in 0 days).  
```shell
openssl req -x509 -sha256 -new -nodes -key rootCAKey.pem -days 3650 -out rootCACert.pem -extensions v3_ca -config openssl.cnf
```

## Configuring trust in AWS
In order to configure the trust identity we need to add some objects in AWS. In the [terraform](./terraform/) subfolder there is an example configuration to add
| Variable | Description |
|---|---|
| self_managed_ca_trust_anchor | The Certificate Autohity that AWS will trust when getting a client certificate |
| self_managed_ca_role | Role for Roles Anywhere to Assume an identity |
| route53_policy | A sample IAM policy to attach to to allow using Cert-Manager with Route53 |
| route53_attachment | Allow us to assume the route53_policy from self_managed_ca_role |
| self_managed_ca_profile | A profile that is the entrypoint from the trust anchor to the first role |

For your usecase you should modify create policy, attachment and profile that matches your need.
Profiles also allows you to specify what requirements you have for your certificate for it to be allows to use a role. Specific common name or similar.

After using Terraform Apply you will get the output ARN's to use for for aws-signing-helper later

## Configuring the kubernetes cluster

For us to issue Certificates to services from the rootCA we utilize Cert-Manager in kubernetes.
Assuming that you already have [Cert-Manager](https://cert-manager.io/) installed you then need to configure a CA issuer that utilizes the generated certiticates.
For more details on configuring a CA issuer in Cert-Manager, refer to the [Cert-Manager CA Issuer documentation](https://cert-manager.io/docs/configuration/ca/).

In [`iam-ra`](./iam-ra/) there is a kustomization that allows to take the already generated rootCA files and deploy them as secret and create a ClusterIssuer.

### ⚠️ Be Aware ⚠️

> **:warning: Important Considerations**
>
> - **Root CA Security:** Keep your `rootCAKey.pem` private and secure. Exposure of this key compromises your entire trust chain.
> - **ClusterIssuer:** A you will be able to utilize the ClusterIssuer anywhere in the cluster unless you have a policy agent that limits creating of Certificate or Ingress resources. So make sure this is what you want.
> - **Issued Certificate:** An issued Certificate will be able to assume the role you have configured ANYWHERE. This includes from a suspicious ip. So be sure to keep track of your Certificates and make them short lived.

### Issuing a certificate for a service
When you need to issue a certificate Cert-Manager can do that for you based on the ClusterIssuer
This is done in [`iamra-ss.yaml`](./iam-ra/iamra-ss.yaml)

Now you have a Secret that you can utilize for aws-signing-helper

## AWS-Signing-Helper
With ARN's and Certificate we are not ready to convert these to a token. This is done using the 
[aws_signing_helper](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html) that have several processes forgetting credentials.
In this repository we have an example with a docker container that is more open then the regular one. Go to [`deployment`](../deployment) for an example in how to deploy this to kubernetes.
There is also an alternative to convert the credential file to a secret in [secret-updater](https://github.com/SimonStiil/aws-signing-helper-secret-updater).

## Example usecase
In a company they use a AWS Private CA in a central account. This is then shared with other organization corporate accounts. I would like to issue certificates form my on-premises cluster using this CA

First i do all of the setup in [`iam-ra`](./iam-ra/) to deploy the aws-signing-helper in my cert-manager namespace.

For issuing certificates [aws-privateca-issuer](https://github.com/cert-manager/aws-privateca-issuer) can do this for us.
It needs to be configured in a way where it is possible to utilize the `AWS_EC2_METADATA_SERVICE_ENDPOINT` setup.

```bash
helm repo add awspca https://cert-manager.github.io/aws-privateca-issuer
helm upgrade --install aws-privateca-issuer awspca/aws-privateca-issuer --namespace cert-manager --values aws-private-ca/aws-privateca-issuer-values.yaml
```

There we setup where to find the endpoint and what region to use. Substitute with your own region.
You need to set region in either env or issuer. [`aws-issuer.yaml`](./aws-private-ca/aws-issuer.yaml) substitute arn with the arn of your aws-acm-pca.

There are limitations when using aws-privateca-issuer That need to be additionally configured when using annotations. 
Usually you only need `cert-manager.io/issuer` but to use this as a cluster issuer you need both `cert-manager.io/issuer-kind` and `cert-manager.io/issuer-group`. As this is a "Shared" aws-acm-pca, we also need to tell cert-manager the type of certificate to issue with `cert-manager.io/usages`.
```yaml
    cert-manager.io/issuer: "pca-issuer"
    cert-manager.io/issuer-kind: AWSPCAClusterIssuer
    cert-manager.io/issuer-group: awspca.cert-manager.io
    cert-manager.io/usages: "server auth,client auth"
```
An example of this can be seen in [`whoami.yaml`](./aws-private-ca/whoami.yaml)