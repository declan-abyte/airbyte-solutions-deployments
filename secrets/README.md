# Secrets Management

This directory contains encrypted secrets for Airbyte deployments using Mozilla SOPS.

## Overview

Secrets are encrypted at rest in Git using SOPS (Secrets OPerationS) with cloud KMS providers (AWS KMS, GCP KMS, or Azure Key Vault).

## Prerequisites

1. Install SOPS:
   ```bash
   # macOS
   brew install sops
   
   # Linux
   wget https://github.com/mozilla/sops/releases/download/v3.8.1/sops-v3.8.1.linux
   ```

2. Configure cloud credentials (AWS, GCP, or Azure)

3. Update `.sops.yaml` with your KMS key IDs

## Usage

### Creating a New Secret

```bash
# Create unencrypted secret file
cat > secrets/dev/secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: airbyte-postgresql-secret
  namespace: airbyte
type: Opaque
stringData:
  postgresql-password: your-password-here
EOF

# Encrypt the secret
sops -e secrets/dev/secrets.yaml > secrets/dev/secrets.enc.yaml

# Remove unencrypted file
rm secrets/dev/secrets.yaml
```

### Editing an Encrypted Secret

```bash
# Edit in place (decrypts, opens editor, re-encrypts)
sops secrets/dev/secrets.enc.yaml
```

### Viewing an Encrypted Secret

```bash
# Decrypt and view
sops -d secrets/dev/secrets.enc.yaml
```

### Deploying Secrets

```bash
# Decrypt and apply to cluster
sops -d secrets/dev/secrets.enc.yaml | kubectl apply -f -
```

## Secret Structure

Each environment should have the following secrets:

1. **PostgreSQL Secret**
   - `postgresql-password`: Database password

2. **Minio Secret**
   - `root-user`: Minio access key
   - `root-password`: Minio secret key

3. **Additional Secrets**
   - API keys for connectors
   - OAuth credentials
   - Webhook secrets

## Best Practices

1. **Never commit unencrypted secrets** - Use `.gitignore` to prevent this
2. **Rotate secrets regularly** - Especially for production
3. **Use different encryption keys per environment**
4. **Limit KMS key access** - Use IAM policies to restrict who can decrypt
5. **Audit secret access** - Monitor KMS key usage

## Alternative: Sealed Secrets

If you prefer not to use SOPS, consider Bitnami Sealed Secrets:

```bash
# Install sealed-secrets controller
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system

# Create sealed secret
kubectl create secret generic my-secret --dry-run=client --from-literal=password=secret -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml
```

## Security Notes

⚠️ **Important Security Considerations**:
- Encrypted secrets are safe to commit to Git
- Anyone with KMS decrypt permissions can view secrets
- Use separate KMS keys for each environment
- Rotate KMS keys according to your security policy
- Monitor KMS key usage for anomalies

