# Crossplane Multi-Cloud Infrastructure

**Cloud-agnostic infrastructure management using Kubernetes Custom Resources**

## Overview

Crossplane extends Kubernetes to manage cloud infrastructure declaratively. Instead of writing cloud-specific Terraform/Pulumi code, define infrastructure as Kubernetes resources that work across AWS, Azure, and GCP.

## Why Crossplane?

### Traditional IaC Challenges

```
Problem: Different tools per cloud
AWS → Terraform AWS Provider
Azure → ARM Templates / Terraform Azure Provider
GCP → Deployment Manager / Terraform GCP Provider

Result: 3 different codebases, 3 different workflows
```

### Crossplane Solution

```
Solution: Single Kubernetes API
kubectl apply -f vehicle-cluster.yaml

Crossplane translates to:
- AWS EKS + EC2 Node Groups
- Azure AKS + Virtual Machine Scale Sets
- GCP GKE + Managed Instance Groups
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Kubernetes Cluster                      │
│                                                          │
│  ┌────────────────────────────────────────────┐        │
│  │         Crossplane Controllers              │        │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │        │
│  │  │   AWS    │  │  Azure   │  │   GCP    │ │        │
│  │  │ Provider │  │ Provider │  │ Provider │ │        │
│  │  └──────────┘  └──────────┘  └──────────┘ │        │
│  └────────────────────────────────────────────┘        │
│                         │                               │
└─────────────────────────┼───────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
    │   AWS   │     │  Azure  │     │   GCP   │
    │   API   │     │   API   │     │   API   │
    └─────────┘     └─────────┘     └─────────┘
```

## Installation

### Prerequisites

- Kubernetes cluster (1.25+)
- kubectl configured
- Helm 3.x

### Install Crossplane

```bash
# Add Crossplane Helm repository
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
helm install crossplane \
  --namespace crossplane-system \
  --create-namespace \
  crossplane-stable/crossplane

# Verify installation
kubectl get pods -n crossplane-system
```

### Install Cloud Providers

```bash
# Install all providers
kubectl apply -f providers/setup.yaml

# Wait for providers to become healthy
kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-aws --timeout=300s
kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-azure --timeout=300s
kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-gcp --timeout=300s
```

### Configure Cloud Credentials

#### AWS

```bash
# Option 1: AWS credentials file
kubectl create secret generic aws-credentials \
  -n crossplane-system \
  --from-file=credentials=$HOME/.aws/credentials

# Option 2: IAM Roles for Service Accounts (IRSA) - Recommended for EKS
kubectl annotate serviceaccount -n crossplane-system provider-aws \
  eks.amazonaws.com/role-arn=arn:aws:iam::123456789012:role/crossplane-provider-aws
```

#### Azure

```bash
# Create service principal
az ad sp create-for-rbac \
  --sdk-auth \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> > azure-credentials.json

# Create secret
kubectl create secret generic azure-credentials \
  -n crossplane-system \
  --from-file=credentials=azure-credentials.json

# Clean up
rm azure-credentials.json
```

#### GCP

```bash
# Create service account
gcloud iam service-accounts create crossplane-sa \
  --display-name "Crossplane Service Account"

# Grant permissions
gcloud projects add-iam-policy-binding <project-id> \
  --member serviceAccount:crossplane-sa@<project-id>.iam.gserviceaccount.com \
  --role roles/container.admin

gcloud projects add-iam-policy-binding <project-id> \
  --member serviceAccount:crossplane-sa@<project-id>.iam.gserviceaccount.com \
  --role roles/compute.admin

# Create key
gcloud iam service-accounts keys create gcp-credentials.json \
  --iam-account crossplane-sa@<project-id>.iam.gserviceaccount.com

# Create secret
kubectl create secret generic gcp-credentials \
  -n crossplane-system \
  --from-file=credentials=gcp-credentials.json

# Clean up
rm gcp-credentials.json
```

## Usage

### Define Composite Resources

Composite Resources (XRs) are cloud-agnostic abstractions:

```yaml
# vehicle-cluster-xrd.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xvehicleclusters.automotive.example.com
spec:
  group: automotive.example.com
  names:
    kind: XVehicleCluster
    plural: xvehicleclusters
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                parameters:
                  type: object
                  properties:
                    region:
                      type: string
                    nodeSize:
                      type: string
                      enum: [small, medium, large]
                    nodeCount:
                      type: integer
```

### Create Compositions

Compositions map XRs to cloud-specific resources:

```yaml
# aws-composition.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: vehicle-cluster-aws
  labels:
    provider: aws
spec:
  compositeTypeRef:
    apiVersion: automotive.example.com/v1alpha1
    kind: XVehicleCluster
  resources:
    - name: eks-cluster
      base:
        apiVersion: eks.aws.upbound.io/v1beta1
        kind: Cluster
        spec:
          forProvider:
            region: us-east-1
            version: "1.29"
```

### Deploy Infrastructure

#### Deploy to AWS

```bash
# Apply compositions
kubectl apply -f compositions/vehicle-cluster.yaml

# Create claim
cat <<EOF | kubectl apply -f -
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: vehicle-fleet-aws
  namespace: default
spec:
  parameters:
    region: us-east-1
    nodeSize: medium
    nodeCount: 3
  compositionSelector:
    matchLabels:
      provider: aws
  writeConnectionSecretToRef:
    name: vehicle-fleet-aws-kubeconfig
EOF
```

#### Deploy to Azure

```bash
cat <<EOF | kubectl apply -f -
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: vehicle-fleet-azure
  namespace: default
spec:
  parameters:
    region: eastus
    nodeSize: medium
    nodeCount: 3
  compositionSelector:
    matchLabels:
      provider: azure
  writeConnectionSecretToRef:
    name: vehicle-fleet-azure-kubeconfig
EOF
```

#### Deploy to GCP

```bash
cat <<EOF | kubectl apply -f -
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: vehicle-fleet-gcp
  namespace: default
spec:
  parameters:
    region: us-central1
    nodeSize: medium
    nodeCount: 3
  compositionSelector:
    matchLabels:
      provider: gcp
  writeConnectionSecretToRef:
    name: vehicle-fleet-gcp-kubeconfig
EOF
```

### Check Status

```bash
# List all clusters
kubectl get vehicleclusters

# Get detailed status
kubectl describe vehiclecluster vehicle-fleet-aws

# Check managed resources
kubectl get managed | grep vehicle-fleet-aws

# Get kubeconfig
kubectl get secret vehicle-fleet-aws-kubeconfig -o jsonpath='{.data.kubeconfig}' | base64 -d > kubeconfig-aws.yaml
export KUBECONFIG=kubeconfig-aws.yaml
kubectl get nodes
```

## Advantages vs Terraform/Pulumi

| Feature | Terraform | Pulumi | Crossplane |
|---------|-----------|--------|------------|
| **Language** | HCL | TypeScript/Python/Go | Kubernetes YAML |
| **State Management** | External state file | External state | Kubernetes etcd |
| **GitOps Ready** | Via Atlantis | Via automation | Native (ArgoCD/Flux) |
| **RBAC** | External | External | Kubernetes RBAC |
| **Drift Detection** | `terraform plan` | `pulumi preview` | Automatic reconciliation |
| **Multi-Cloud** | Multiple providers | Multiple SDKs | Single API |
| **Lifecycle** | Create/Update/Delete | Create/Update/Delete | Kubernetes controllers |
| **Learning Curve** | Medium | High (programming) | Medium (K8s knowledge) |

## GitOps Workflow

### With ArgoCD

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vehicle-infrastructure
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/infrastructure
    targetRevision: main
    path: crossplane/claims
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### With Flux

```yaml
# flux-kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: vehicle-infrastructure
  namespace: flux-system
spec:
  interval: 5m
  path: ./crossplane/claims
  prune: true
  sourceRef:
    kind: GitRepository
    name: infrastructure
  validation: client
```

## Cost Management

### Resource Tagging

```yaml
# Automatic tagging via composition
patches:
  - type: FromCompositeFieldPath
    fromFieldPath: metadata.labels[cost-center]
    toFieldPath: spec.forProvider.tags[CostCenter]
  - type: FromCompositeFieldPath
    fromFieldPath: metadata.labels[environment]
    toFieldPath: spec.forProvider.tags[Environment]
```

### Budget Alerts

```yaml
# AWS Budget Alert via Crossplane
apiVersion: budgets.aws.upbound.io/v1beta1
kind: Budget
metadata:
  name: vehicle-fleet-budget
spec:
  forProvider:
    budgetType: COST
    limitAmount: "10000"
    limitUnit: USD
    timeUnit: MONTHLY
    notification:
      - comparisonOperator: GREATER_THAN
        threshold: 80
        thresholdType: PERCENTAGE
        notificationType: ACTUAL
```

## Security Best Practices

### 1. Least Privilege IAM

```yaml
# AWS IAM Role with minimal permissions
apiVersion: iam.aws.upbound.io/v1beta1
kind: Role
metadata:
  name: vehicle-app-role
spec:
  forProvider:
    assumeRolePolicy: |
      {
        "Version": "2012-10-17",
        "Statement": [{
          "Effect": "Allow",
          "Principal": {"Federated": "arn:aws:iam::123456789012:oidc-provider/..."},
          "Action": "sts:AssumeRoleWithWebIdentity"
        }]
      }
```

### 2. Network Isolation

```yaml
# Private subnets for sensitive resources
patches:
  - type: FromCompositeFieldPath
    fromFieldPath: spec.parameters.privateSubnetIds
    toFieldPath: spec.forProvider.subnetIds
```

### 3. Encryption

```yaml
# Enable encryption at rest
patches:
  - type: FromCompositeFieldPath
    fromFieldPath: spec.parameters.kmsKeyId
    toFieldPath: spec.forProvider.encryptionConfiguration[0].resources[0]
```

## Troubleshooting

### Provider Not Healthy

```bash
# Check provider status
kubectl get providers

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws --tail=100

# Restart provider
kubectl delete pod -n crossplane-system -l pkg.crossplane.io/provider=provider-aws
```

### Resource Not Creating

```bash
# Check claim status
kubectl describe vehiclecluster vehicle-fleet-aws

# Check composite resource
kubectl get composite

# Check managed resources
kubectl get managed

# Check events
kubectl get events --sort-by='.lastTimestamp' | grep vehicle-fleet-aws
```

### Authentication Issues

```bash
# Verify credentials secret exists
kubectl get secret -n crossplane-system aws-credentials

# Check provider config
kubectl get providerconfig

# Test credentials
kubectl run -it --rm aws-cli --image=amazon/aws-cli --restart=Never -- sts get-caller-identity
```

## Migration from Terraform

### Step 1: Import Existing Resources

```bash
# Use Crossplane import to bring existing infrastructure under management
crossplane beta import aws --resource-file=existing-eks.yaml

# Or use Terrajet to auto-generate Crossplane resources from Terraform state
terraform state pull | crossplane beta convert --input-format=terraform
```

### Step 2: Gradual Migration

1. Start with non-critical resources
2. Deploy new resources via Crossplane
3. Import existing resources incrementally
4. Remove Terraform code once verified

### Step 3: Validation

```bash
# Compare Terraform vs Crossplane outputs
terraform output -json > tf-output.json
kubectl get vehiclecluster vehicle-fleet-aws -o json | jq .status > crossplane-output.json
diff tf-output.json crossplane-output.json
```

## Advanced Patterns

### Multi-Cluster Management

```yaml
# Deploy to multiple clusters simultaneously
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: vehicle-fleet-multi
spec:
  parameters:
    regions:
      - us-east-1
      - eu-west-1
      - ap-south-1
  compositionSelector:
    matchLabels:
      pattern: multi-region
```

### Policy Enforcement

```yaml
# Kyverno policy: Require encryption
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-cluster-encryption
spec:
  validationFailureAction: enforce
  rules:
    - name: check-encryption
      match:
        any:
          - resources:
              kinds:
                - VehicleCluster
      validate:
        message: "Clusters must have encryption enabled"
        pattern:
          spec:
            parameters:
              encryptionEnabled: true
```

### Self-Service Portals

```yaml
# Backstage integration for developer self-service
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: vehicle-cluster
  annotations:
    crossplane.io/claim-name: VehicleCluster
spec:
  type: service
  lifecycle: production
  owner: platform-team
```

## References

- [Crossplane Documentation](https://crossplane.io/docs/)
- [Upbound Provider AWS](https://marketplace.upbound.io/providers/upbound/provider-aws/)
- [Upbound Provider Azure](https://marketplace.upbound.io/providers/upbound/provider-azure/)
- [Upbound Provider GCP](https://marketplace.upbound.io/providers/upbound/provider-gcp/)
- [Crossplane Slack](https://slack.crossplane.io/)
