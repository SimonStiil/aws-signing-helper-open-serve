# AWS Signing Helper Open Serve

This project provides a containerized, Kubernetes-ready deployment of the [AWS Roles Anywhere Credential Helper](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html), patched to allow connections from any host. It is designed for use with [AWS IAM Roles Anywhere for Kubernetes](https://github.com/aws-samples/aws-iam-ra-for-kubernetes) and integrates with [cert-manager](https://cert-manager.io/) for certificate management.

![Architecture](https://github.com/aws-samples/aws-iam-ra-for-kubernetes/blob/main/cert-manager-self-managed-ca/cert-manager-self-managed-ca.png)

## Overview

The container runs the `aws_signing_helper` in `serve` mode, exposing a signing API over HTTP. This enables Kubernetes workloads to obtain AWS credentials using X.509 certificates managed by cert-manager, following the architecture above.

The project includes a demo deployment using Kubernetes manifests and Kustomize, showing how to integrate with cert-manager and configure the necessary AWS Roles Anywhere resources.

## Features

- **Patched Credential Helper**: The helper is modified to listen on all interfaces, not just localhost, enabling remote access within the cluster.
- **cert-manager Integration**: Uses cert-manager to provision and rotate X.509 certificates for authentication.
- **Kubernetes Native**: Includes manifests for deployment, service, configmap, and certificate resources.
- **Configurable via Environment**: All AWS Roles Anywhere ARNs and certificate paths are configurable.

## Prerequisites

- Kubernetes cluster (v1.20+ recommended)
- cert-manager installed and configured
- AWS IAM Roles Anywhere set up with:
  - Trust Anchor
  - Profile
  - IAM Role

## Deployment

### 1. Configure cert-manager Issuer

Ensure you have a `ClusterIssuer` or `Issuer` configured for cert-manager. Example:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  selfSigned: {}
```

### 2. Update ConfigMap

Edit `deployment/configmap.yaml` with your AWS ARNs:

```yaml
data:
  TRUST_ANCHOR_ARN: "arn:aws:rolesanywhere:...:trust-anchor/..."
  PROFILE_ARN: "arn:aws:rolesanywhere:...:profile/..."
  ROLE_ARN: "arn:aws:iam::...:role/..."
```

### 3. Deploy Resources

Apply the manifests using Kustomize:

```sh
kubectl apply -k deployment/
```

This will create:

- A `Certificate` resource (managed by cert-manager)
- A `Secret` containing the certificate and key
- A `ConfigMap` with AWS ARNs
- A `Deployment` running the patched signing helper
- A `Service` exposing the signing helper on port 9911

### 4. Accessing the Signing Helper

The signing helper is exposed as a ClusterIP service (`aws-signing-helper`) on port 9911 in the `cert-manager` namespace. You can access it from other pods in the cluster.

## Environment Variables

The container expects the following environment variables:

- `CERTIFICATE`: Path to the certificate file (e.g., `/etc/certs/tls.crt`)
- `PRIVATE_KEY`: Path to the private key file (e.g., `/etc/certs/tls.key`)
- `TRUST_ANCHOR_ARN`: AWS Roles Anywhere Trust Anchor ARN
- `PROFILE_ARN`: AWS Roles Anywhere Profile ARN
- `ROLE_ARN`: IAM Role ARN to assume

These are set via the deployment manifest and configmap.

## Security Considerations

- The patched helper listens on all interfaces. Restrict access using Kubernetes network policies or run in a private namespace.
- Certificates and keys are mounted from Kubernetes secrets managed by cert-manager.

## References

- [AWS IAM Roles Anywhere for Kubernetes](https://github.com/aws-samples/aws-iam-ra-for-kubernetes)
- [AWS Roles Anywhere Credential Helper](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html)
- [cert-manager](https://cert-manager.io/)

---

*This project is for demonstration and prototyping purposes. Review and adapt for production use.*