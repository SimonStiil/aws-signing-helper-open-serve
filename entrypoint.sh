#!/bin/sh
# Check for required environment variables
# Check for required environment variables
if [ -z "$CERTIFICATE" ]; then
  echo "Error: CERTIFICATE environment variable is required."
  echo "Description: Path to certificate file or a PKCS#11 URI for hardware/software tokens."
  exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
  echo "Error: PRIVATE_KEY environment variable is required."
  echo "Description: Specifies the private key to use for signing. Can be a path to a plaintext private key file, a PKCS#11 URI, or a TPM wrapped key."
  exit 1
fi

if [ -z "$TRUST_ANCHOR_ARN" ]; then
  echo "Error: TRUST_ANCHOR_ARN environment variable is required."
  echo "Description: Trust anchor to use for authentication."
  exit 1
fi

if [ -z "$PROFILE_ARN" ]; then
  echo "Error: PROFILE_ARN environment variable is required."
  echo "Description: Profile to pull policies, attribute mappings, and other data from."
  exit 1
fi

if [ -z "$ROLE_ARN" ]; then
  echo "Error: ROLE_ARN environment variable is required."
  echo "Description: The target role to assume."
  exit 1
fi
exec /usr/local/bin/aws_signing_helper serve \
  --certificate "$CERTIFICATE" \
  --private-key "$PRIVATE_KEY" \
  --trust-anchor-arn "$TRUST_ANCHOR_ARN" \
  --profile-arn "$PROFILE_ARN" \
  --role-arn "$ROLE_ARN" \
  ${PORT:+--port "$PORT"} \
  ${HOP_LIMIT:+--hop-limit "$HOP_LIMIT"}