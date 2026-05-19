# Multi-Cloud Infrastructure Quick Start

**Get your vehicle fleet infrastructure running in AWS, Azure, or GCP in under 30 minutes.**

## Choose Your Path

### Path 1: Native Terraform (Recommended for single cloud)

Best for teams already using Terraform or deploying to a single cloud provider.

**Time**: 20 minutes
**Complexity**: Low
**Best for**: Production deployments on single cloud

### Path 2: Pulumi Multi-Cloud (Recommended for multi-cloud)

Best for teams wanting single codebase deploying to multiple clouds.

**Time**: 25 minutes
**Complexity**: Medium
**Best for**: Multi-cloud deployments, TypeScript/Python teams

### Path 3: Crossplane (Recommended for Kubernetes-native)

Best for teams with Kubernetes expertise wanting cloud-agnostic IaC.

**Time**: 30 minutes
**Complexity**: High
**Best for**: GitOps workflows, platform engineering teams

---

## Path 1: Native Terraform - Azure IoT Hub + AKS

### Prerequisites

```bash
# Install tools
brew install terraform azure-cli

# Or on Linux
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Login to Azure
az login
```

### Deploy in 5 Commands

```bash
# 1. Clone repository
cd terraform/azure/examples/vehicle-fleet

# 2. Initialize Terraform
terraform init

# 3. Create config file
cat > environments/dev.tfvars <<EOF
project_name = "vehicle-fleet-dev"
location     = "eastus"
environment  = "dev"

# IoT Hub
iot_hub_sku_name     = "S1"
iot_hub_sku_capacity = 1

# AKS
kubernetes_version = "1.29"
system_node_pool_node_count = 3
create_user_node_pool = true

# Cosmos DB
enable_multiple_write_locations = false
consistency_level = "Session"
EOF

# 4. Preview changes
terraform plan -var-file=environments/dev.tfvars

# 5. Deploy (takes ~15 minutes)
terraform apply -var-file=environments/dev.tfvars -auto-approve
```

### Get Connection Details

```bash
# IoT Hub hostname
terraform output iot_hub_hostname

# AKS kubeconfig
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)

# Test connection
kubectl get nodes

# Cosmos DB connection string
terraform output -raw cosmos_connection_string
```

### Deploy Sample Application

```bash
# Create namespace
kubectl create namespace vehicle-app

# Deploy sample app
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: telemetry-processor
  namespace: vehicle-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: telemetry-processor
  template:
    metadata:
      labels:
        app: telemetry-processor
    spec:
      containers:
      - name: processor
        image: mcr.microsoft.com/azure-samples/iot-telemetry-processor:latest
        env:
        - name: IOT_HUB_CONNECTION_STRING
          valueFrom:
            secretKeyRef:
              name: iot-hub-secret
              key: connection-string
        - name: COSMOS_CONNECTION_STRING
          valueFrom:
            secretKeyRef:
              name: cosmos-secret
              key: connection-string
EOF
```

### Connect Your First Vehicle

```bash
# Create device identity
az iot hub device-identity create \
  --hub-name $(terraform output -raw iot_hub_name) \
  --device-id vehicle-001

# Get device connection string
az iot hub device-identity connection-string show \
  --hub-name $(terraform output -raw iot_hub_name) \
  --device-id vehicle-001 \
  --output tsv

# Send test telemetry
az iot device send-d2c-message \
  --hub-name $(terraform output -raw iot_hub_name) \
  --device-id vehicle-001 \
  --data '{"vehicleId":"vehicle-001","speed":65,"batteryLevel":85,"latitude":40.7128,"longitude":-74.0060,"timestamp":"2026-03-19T10:30:00Z"}'

# Verify in Cosmos DB
az cosmosdb sql query \
  --account-name $(terraform output -raw cosmos_account_name) \
  --database-name vehicle-fleet \
  --container-name telemetry \
  --query "SELECT * FROM c WHERE c.vehicleId = 'vehicle-001' ORDER BY c.timestamp DESC OFFSET 0 LIMIT 10"
```

### Clean Up

```bash
# Delete all resources
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

---

## Path 2: Pulumi Multi-Cloud

### Prerequisites

```bash
# Install Pulumi
curl -fsSL https://get.pulumi.com | sh

# Install Node.js
brew install node  # or nvm install 20

# Cloud CLIs
brew install awscli azure-cli google-cloud-sdk
```

### Deploy to AWS

```bash
# Navigate to Pulumi project
cd terraform/multi-cloud/pulumi/hybrid

# Install dependencies
npm install

# Initialize Pulumi stack
pulumi login  # or pulumi login --local for offline
pulumi stack init dev-aws

# Configure
pulumi config set cloud aws
pulumi config set project-name vehicle-fleet
pulumi config set region us-east-1
pulumi config set aws:region us-east-1

# Deploy
pulumi up --yes

# Outputs
pulumi stack output iot_endpoint
pulumi stack output cluster_name
pulumi stack output database_endpoint
```

### Switch to Azure

```bash
# Create new stack
pulumi stack init dev-azure

# Configure
pulumi config set cloud azure
pulumi config set project-name vehicle-fleet
pulumi config set region eastus
pulumi config set azure-native:location eastus

# Login to Azure
az login

# Deploy same code to Azure
pulumi up --yes
```

### Deploy to GCP

```bash
# Create new stack
pulumi stack init dev-gcp

# Configure
pulumi config set cloud gcp
pulumi config set project-name vehicle-fleet
pulumi config set region us-central1
pulumi config set gcp:project your-project-id
pulumi config set gcp:region us-central1

# Login to GCP
gcloud auth application-default login

# Deploy same code to GCP
pulumi up --yes
```

### Compare Costs Across Clouds

```bash
# AWS cost
pulumi stack select dev-aws
pulumi stack output | jq '.'

# Azure cost
pulumi stack select dev-azure
pulumi stack output | jq '.'

# GCP cost
pulumi stack select dev-gcp
pulumi stack output | jq '.'

# Generate cost report
pulumi up --json | jq '.totalCost'
```

---

## Path 3: Crossplane Kubernetes-Native

### Prerequisites

```bash
# Kubernetes cluster (use kind for local testing)
brew install kind kubectl helm

# Create cluster
kind create cluster --name crossplane-demo

# Verify
kubectl cluster-info
```

### Install Crossplane

```bash
# Add Helm repo
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
helm install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace \
  --wait

# Verify
kubectl get pods -n crossplane-system
```

### Install Cloud Providers

```bash
cd terraform/multi-cloud/crossplane

# Install providers
kubectl apply -f providers/setup.yaml

# Wait for providers
kubectl wait --for=condition=healthy provider.pkg.crossplane.io --all --timeout=5m
```

### Configure Cloud Credentials

```bash
# AWS
kubectl create secret generic aws-credentials \
  -n crossplane-system \
  --from-file=credentials=$HOME/.aws/credentials

# Azure
az ad sp create-for-rbac --sdk-auth > azure-creds.json
kubectl create secret generic azure-credentials \
  -n crossplane-system \
  --from-file=credentials=azure-creds.json
rm azure-creds.json

# GCP
gcloud iam service-accounts keys create gcp-creds.json \
  --iam-account crossplane@your-project.iam.gserviceaccount.com
kubectl create secret generic gcp-credentials \
  -n crossplane-system \
  --from-file=credentials=gcp-creds.json
rm gcp-creds.json
```

### Deploy Infrastructure

```bash
# Install compositions
kubectl apply -f compositions/vehicle-cluster.yaml

# Deploy to AWS
kubectl apply -f - <<EOF
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: vehicle-fleet-aws
spec:
  parameters:
    region: us-east-1
    nodeSize: medium
    nodeCount: 3
  compositionSelector:
    matchLabels:
      provider: aws
  writeConnectionSecretToRef:
    name: aws-kubeconfig
EOF

# Check status
kubectl get vehicleclusters
kubectl describe vehiclecluster vehicle-fleet-aws

# Get kubeconfig (once ready)
kubectl get secret aws-kubeconfig -o jsonpath='{.data.kubeconfig}' | base64 -d > kubeconfig-aws.yaml
export KUBECONFIG=kubeconfig-aws.yaml
kubectl get nodes
```

### Deploy to Multiple Clouds

```bash
# Azure
kubectl apply -f - <<EOF
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: vehicle-fleet-azure
spec:
  parameters:
    region: eastus
    nodeSize: medium
    nodeCount: 3
  compositionSelector:
    matchLabels:
      provider: azure
  writeConnectionSecretToRef:
    name: azure-kubeconfig
EOF

# GCP
kubectl apply -f - <<EOF
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: vehicle-fleet-gcp
spec:
  parameters:
    region: us-central1
    nodeSize: medium
    nodeCount: 3
  compositionSelector:
    matchLabels:
      provider: gcp
  writeConnectionSecretToRef:
    name: gcp-kubeconfig
EOF

# Monitor all deployments
watch kubectl get vehicleclusters
```

---

## Cost Estimates

### Dev Environment (10 vehicles, 1 msg/sec)

| Cloud | IoT | Compute | Database | Storage | Total/Month |
|-------|-----|---------|----------|---------|-------------|
| **AWS** | $25 | $220 | $180 | $50 | **$475** |
| **Azure** | $50 | $200 | $300 | $40 | **$590** |
| **GCP** | $15 | $200 | $150 | $45 | **$410** |

### Production (10,000 vehicles, 1 msg/sec)

| Cloud | IoT | Compute | Database | Storage | Total/Month |
|-------|-----|---------|----------|---------|-------------|
| **AWS** | $200 | $800 | $600 | $250 | **$1,850** |
| **Azure** | $250 | $700 | $1,200 | $200 | **$2,350** |
| **GCP** | $150 | $700 | $500 | $220 | **$1,570** |

**Winner**: GCP for cost optimization

---

## Next Steps

### 1. Enable Monitoring

```bash
# Install Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Login: admin / prom-operator
# Import dashboard: 15759 (Kubernetes Cluster Monitoring)
```

### 2. Set Up CI/CD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Enable Auto-Scaling

```bash
# Install Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=vehicle-fleet-cluster

# Install KEDA for app autoscaling
helm repo add kedacore https://kedacore.github.io/charts
helm install keda kedacore/keda --namespace keda --create-namespace
```

### 4. Implement Security

```bash
# Install Falco for runtime security
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace

# Install OPA Gatekeeper for policy enforcement
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace
```

---

## Troubleshooting

### Terraform Fails

```bash
# Enable debug logging
export TF_LOG=DEBUG

# Check state
terraform state list

# Fix corrupted state
terraform state rm <resource>
terraform import <resource> <id>
```

### Pulumi Fails

```bash
# Enable verbose logging
pulumi up --debug --verbose

# Refresh state
pulumi refresh

# Fix stuck resources
pulumi stack export | jq '.deployment.resources' > resources.json
# Edit resources.json to remove problematic resources
pulumi stack import --file resources.json
```

### Crossplane Fails

```bash
# Check provider status
kubectl get providers

# View provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws

# Check resource status
kubectl describe vehiclecluster vehicle-fleet-aws

# Force reconciliation
kubectl annotate vehiclecluster vehicle-fleet-aws crossplane.io/paused-

# Delete and recreate
kubectl delete vehiclecluster vehicle-fleet-aws
kubectl apply -f vehicle-cluster.yaml
```

---

## Getting Help

- **Documentation**: See `/terraform/MULTI_CLOUD_GUIDE.md`
- **Slack**: #devops-multi-cloud
- **Email**: devops@example.com
- **Issues**: File ticket with label `multi-cloud-iac`

## References

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Pulumi AWS Guide](https://www.pulumi.com/docs/clouds/aws/)
- [Crossplane Documentation](https://crossplane.io/docs/)
- [Azure IoT Hub Quickstart](https://docs.microsoft.com/en-us/azure/iot-hub/quickstart-send-telemetry-cli)
