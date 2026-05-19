/**
 * Pulumi Multi-Cloud Vehicle Fleet Infrastructure
 * Deploys to AWS, Azure, or GCP based on configuration
 *
 * Usage:
 *   pulumi config set cloud aws|azure|gcp
 *   pulumi config set project-name vehicle-fleet
 *   pulumi config set region us-east-1|eastus|us-central1
 *   pulumi up
 */

import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as azure from "@pulumi/azure-native";
import * as gcp from "@pulumi/gcp";

// Configuration
const config = new pulumi.Config();
const cloud = config.require("cloud"); // aws, azure, or gcp
const projectName = config.require("project-name");
const region = config.require("region");
const environment = config.get("environment") || "dev";

// Tags/Labels applied to all resources
const commonTags = {
    Project: projectName,
    Environment: environment,
    ManagedBy: "pulumi",
    Cloud: cloud,
};

interface InfrastructureOutputs {
    iotEndpoint: pulumi.Output<string>;
    clusterName: pulumi.Output<string>;
    databaseEndpoint: pulumi.Output<string>;
    storageBucket: pulumi.Output<string>;
}

/**
 * Deploy AWS Infrastructure
 */
function deployAWS(): InfrastructureOutputs {
    // VPC
    const vpc = new aws.ec2.Vpc(`${projectName}-vpc`, {
        cidrBlock: "10.0.0.0/16",
        enableDnsHostnames: true,
        enableDnsSupport: true,
        tags: { ...commonTags, Name: `${projectName}-vpc` },
    });

    // Subnets
    const publicSubnet1 = new aws.ec2.Subnet(`${projectName}-public-1`, {
        vpcId: vpc.id,
        cidrBlock: "10.0.1.0/24",
        availabilityZone: `${region}a`,
        mapPublicIpOnLaunch: true,
        tags: { ...commonTags, Name: `${projectName}-public-1` },
    });

    const publicSubnet2 = new aws.ec2.Subnet(`${projectName}-public-2`, {
        vpcId: vpc.id,
        cidrBlock: "10.0.2.0/24",
        availabilityZone: `${region}b`,
        mapPublicIpOnLaunch: true,
        tags: { ...commonTags, Name: `${projectName}-public-2` },
    });

    // Internet Gateway
    const igw = new aws.ec2.InternetGateway(`${projectName}-igw`, {
        vpcId: vpc.id,
        tags: { ...commonTags, Name: `${projectName}-igw` },
    });

    // Route Table
    const routeTable = new aws.ec2.RouteTable(`${projectName}-rt`, {
        vpcId: vpc.id,
        routes: [{
            cidrBlock: "0.0.0.0/0",
            gatewayId: igw.id,
        }],
        tags: { ...commonTags, Name: `${projectName}-rt` },
    });

    // Route Table Associations
    new aws.ec2.RouteTableAssociation(`${projectName}-rta-1`, {
        subnetId: publicSubnet1.id,
        routeTableId: routeTable.id,
    });

    new aws.ec2.RouteTableAssociation(`${projectName}-rta-2`, {
        subnetId: publicSubnet2.id,
        routeTableId: routeTable.id,
    });

    // IoT Core
    const iotPolicy = new aws.iot.Policy(`${projectName}-iot-policy`, {
        policy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Action: ["iot:Connect", "iot:Publish", "iot:Subscribe", "iot:Receive"],
                Resource: "*",
            }],
        }),
    });

    // IoT Thing Type
    const thingType = new aws.iot.ThingType(`${projectName}-vehicle`, {
        name: `${projectName}-vehicle`,
        properties: {
            thingTypeDescription: "Vehicle IoT device",
            searchableAttributes: ["vehicleId", "model", "year"],
        },
    });

    // EKS Cluster
    const eksRole = new aws.iam.Role(`${projectName}-eks-role`, {
        assumeRolePolicy: aws.iam.assumeRolePolicyForPrincipal({
            Service: "eks.amazonaws.com",
        }),
        tags: commonTags,
    });

    new aws.iam.RolePolicyAttachment(`${projectName}-eks-policy`, {
        role: eksRole.name,
        policyArn: "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    });

    const eksCluster = new aws.eks.Cluster(`${projectName}-eks`, {
        roleArn: eksRole.arn,
        vpcConfig: {
            subnetIds: [publicSubnet1.id, publicSubnet2.id],
        },
        version: "1.29",
        tags: commonTags,
    });

    // Node Group
    const nodeRole = new aws.iam.Role(`${projectName}-node-role`, {
        assumeRolePolicy: aws.iam.assumeRolePolicyForPrincipal({
            Service: "ec2.amazonaws.com",
        }),
        tags: commonTags,
    });

    ["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly"].forEach(policy => {
        new aws.iam.RolePolicyAttachment(`${projectName}-node-${policy}`, {
            role: nodeRole.name,
            policyArn: `arn:aws:iam::aws:policy/${policy}`,
        });
    });

    new aws.eks.NodeGroup(`${projectName}-node-group`, {
        clusterName: eksCluster.name,
        nodeRoleArn: nodeRole.arn,
        subnetIds: [publicSubnet1.id, publicSubnet2.id],
        scalingConfig: {
            desiredSize: 3,
            minSize: 2,
            maxSize: 10,
        },
        instanceTypes: ["t3.large"],
        tags: commonTags,
    });

    // Timestream Database
    const timestreamDb = new aws.timestreamwrite.Database(`${projectName}-timestream`, {
        databaseName: projectName,
        tags: commonTags,
    });

    const timestreamTable = new aws.timestreamwrite.Table(`${projectName}-telemetry`, {
        databaseName: timestreamDb.databaseName,
        tableName: "telemetry",
        retentionProperties: {
            memoryStoreRetentionPeriodInHours: 24,
            magneticStoreRetentionPeriodInDays: 90,
        },
        tags: commonTags,
    });

    // S3 Bucket
    const s3Bucket = new aws.s3.Bucket(`${projectName}-storage`, {
        bucket: `${projectName}-storage-${aws.getCallerIdentityOutput().accountId}`,
        tags: commonTags,
    });

    new aws.s3.BucketPublicAccessBlock(`${projectName}-storage-block`, {
        bucket: s3Bucket.id,
        blockPublicAcls: true,
        blockPublicPolicy: true,
        ignorePublicAcls: true,
        restrictPublicBuckets: true,
    });

    // Get IoT endpoint
    const iotEndpoint = aws.iot.getEndpointOutput({ endpointType: "iot:Data-ATS" });

    return {
        iotEndpoint: iotEndpoint.endpointAddress,
        clusterName: eksCluster.name,
        databaseEndpoint: pulumi.interpolate`${timestreamDb.databaseName}.${timestreamTable.tableName}`,
        storageBucket: s3Bucket.bucket,
    };
}

/**
 * Deploy Azure Infrastructure
 */
function deployAzure(): InfrastructureOutputs {
    // Resource Group
    const resourceGroup = new azure.resources.ResourceGroup(`${projectName}-rg`, {
        location: region,
        tags: commonTags,
    });

    // Virtual Network
    const vnet = new azure.network.VirtualNetwork(`${projectName}-vnet`, {
        resourceGroupName: resourceGroup.name,
        location: region,
        addressSpace: { addressPrefixes: ["10.0.0.0/16"] },
        tags: commonTags,
    });

    // Subnet for AKS
    const aksSubnet = new azure.network.Subnet(`${projectName}-aks-subnet`, {
        resourceGroupName: resourceGroup.name,
        virtualNetworkName: vnet.name,
        addressPrefix: "10.0.1.0/24",
    });

    // IoT Hub
    const iotHub = new azure.devices.IotHubResource(`${projectName}-iothub`, {
        resourceGroupName: resourceGroup.name,
        location: region,
        sku: {
            name: "S1",
            capacity: 1,
        },
        properties: {
            routing: {
                routes: [],
                fallbackRoute: {
                    name: "$fallback",
                    source: "DeviceMessages",
                    condition: "true",
                    endpointNames: ["events"],
                    isEnabled: true,
                },
            },
        },
        tags: commonTags,
    });

    // Device Provisioning Service
    const dps = new azure.devices.IotDpsResource(`${projectName}-dps`, {
        resourceGroupName: resourceGroup.name,
        location: region,
        sku: {
            name: "S1",
            capacity: 1,
        },
        properties: {
            iotHubs: [{
                connectionString: pulumi.interpolate`HostName=${iotHub.properties.hostName};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.properties.apply(p => p.sharedAccessPolicies?.[0]?.primaryKey || "")}`,
                location: region,
            }],
        },
        tags: commonTags,
    });

    // AKS Cluster
    const aksCluster = new azure.containerservice.ManagedCluster(`${projectName}-aks`, {
        resourceGroupName: resourceGroup.name,
        location: region,
        dnsPrefix: projectName,
        agentPoolProfiles: [{
            name: "system",
            count: 3,
            vmSize: "Standard_D4s_v3",
            mode: "System",
            vnetSubnetID: aksSubnet.id,
            enableAutoScaling: true,
            minCount: 2,
            maxCount: 10,
        }],
        identity: {
            type: "SystemAssigned",
        },
        networkProfile: {
            networkPlugin: "azure",
            serviceCidr: "10.0.64.0/19",
            dnsServiceIP: "10.0.64.10",
        },
        tags: commonTags,
    });

    // Cosmos DB
    const cosmosAccount = new azure.documentdb.DatabaseAccount(`${projectName}-cosmos`, {
        resourceGroupName: resourceGroup.name,
        location: region,
        databaseAccountOfferType: "Standard",
        kind: "MongoDB",
        consistencyPolicy: {
            defaultConsistencyLevel: "Session",
        },
        locations: [{
            locationName: region,
            failoverPriority: 0,
        }],
        capabilities: [{
            name: "EnableMongo",
        }],
        tags: commonTags,
    });

    const database = new azure.documentdb.MongoDBDatabase(`${projectName}-db`, {
        resourceGroupName: resourceGroup.name,
        accountName: cosmosAccount.name,
        resource: {
            id: projectName,
        },
    });

    // Storage Account
    const storageAccount = new azure.storage.StorageAccount(`${projectName}storage`, {
        resourceGroupName: resourceGroup.name,
        location: region,
        sku: { name: "Standard_GRS" },
        kind: "StorageV2",
        tags: commonTags,
    });

    return {
        iotEndpoint: iotHub.properties.hostName,
        clusterName: aksCluster.name,
        databaseEndpoint: cosmosAccount.documentEndpoint,
        storageBucket: storageAccount.primaryBlobEndpoint,
    };
}

/**
 * Deploy GCP Infrastructure
 */
function deployGCP(): InfrastructureOutputs {
    const gcpConfig = new pulumi.Config("gcp");
    const project = gcpConfig.require("project");

    // Enable required APIs
    const services = [
        "compute.googleapis.com",
        "container.googleapis.com",
        "pubsub.googleapis.com",
        "bigtable.googleapis.com",
    ];

    services.forEach(service => {
        new gcp.projects.Service(`${projectName}-${service}`, {
            service: service,
            disableOnDestroy: false,
        });
    });

    // VPC Network
    const network = new gcp.compute.Network(`${projectName}-network`, {
        autoCreateSubnetworks: false,
    });

    const subnet = new gcp.compute.Subnetwork(`${projectName}-subnet`, {
        ipCidrRange: "10.0.0.0/16",
        region: region,
        network: network.id,
        secondaryIpRanges: [
            { rangeName: "pods", ipCidrRange: "10.1.0.0/16" },
            { rangeName: "services", ipCidrRange: "10.2.0.0/16" },
        ],
    });

    // Pub/Sub for IoT
    const telemetryTopic = new gcp.pubsub.Topic(`${projectName}-telemetry`, {
        messageRetentionDuration: "604800s", // 7 days
        labels: commonTags,
    });

    const telemetrySubscription = new gcp.pubsub.Subscription(`${projectName}-telemetry-sub`, {
        topic: telemetryTopic.name,
        ackDeadlineSeconds: 20,
        retainAckedMessages: false,
        messageRetentionDuration: "604800s",
        labels: commonTags,
    });

    // GKE Cluster
    const gkeCluster = new gcp.container.Cluster(`${projectName}-gke`, {
        location: region,
        removeDefaultNodePool: true,
        initialNodeCount: 1,
        network: network.name,
        subnetwork: subnet.name,
        ipAllocationPolicy: {
            clusterSecondaryRangeName: "pods",
            servicesSecondaryRangeName: "services",
        },
        releaseChannel: { channel: "STABLE" },
        workloadIdentityConfig: {
            workloadPool: `${project}.svc.id.goog`,
        },
    });

    new gcp.container.NodePool(`${projectName}-node-pool`, {
        location: region,
        cluster: gkeCluster.name,
        nodeCount: 3,
        autoscaling: {
            minNodeCount: 2,
            maxNodeCount: 10,
        },
        nodeConfig: {
            machineType: "n2-standard-4",
            oauthScopes: [
                "https://www.googleapis.com/auth/cloud-platform",
            ],
            workloadMetadataConfig: {
                mode: "GKE_METADATA",
            },
            labels: commonTags,
        },
    });

    // Bigtable Instance
    const bigtableInstance = new gcp.bigtable.Instance(`${projectName}-bigtable`, {
        displayName: `${projectName} Telemetry`,
        clusters: [{
            clusterId: "cluster-1",
            zone: `${region}-a`,
            numNodes: 3,
            storageType: "SSD",
        }],
        labels: commonTags,
    });

    const bigtableTable = new gcp.bigtable.Table(`${projectName}-telemetry`, {
        instanceName: bigtableInstance.name,
        columnFamilies: [{
            family: "telemetry",
        }],
    });

    // Cloud Storage Bucket
    const bucket = new gcp.storage.Bucket(`${projectName}-storage`, {
        location: region,
        storageClass: "STANDARD",
        uniformBucketLevelAccess: true,
        lifecycleRules: [{
            action: { type: "SetStorageClass", storageClass: "NEARLINE" },
            condition: { age: 30 },
        }, {
            action: { type: "Delete" },
            condition: { age: 365 },
        }],
        labels: commonTags,
    });

    return {
        iotEndpoint: pulumi.interpolate`pubsub.googleapis.com/${telemetryTopic.id}`,
        clusterName: gkeCluster.name,
        databaseEndpoint: pulumi.interpolate`${bigtableInstance.name}/${bigtableTable.name}`,
        storageBucket: bucket.url,
    };
}

// Deploy based on cloud selection
let outputs: InfrastructureOutputs;

switch (cloud) {
    case "aws":
        outputs = deployAWS();
        break;
    case "azure":
        outputs = deployAzure();
        break;
    case "gcp":
        outputs = deployGCP();
        break;
    default:
        throw new Error(`Invalid cloud provider: ${cloud}. Must be aws, azure, or gcp`);
}

// Export outputs
export const cloud_provider = cloud;
export const iot_endpoint = outputs.iotEndpoint;
export const cluster_name = outputs.clusterName;
export const database_endpoint = outputs.databaseEndpoint;
export const storage_bucket = outputs.storageBucket;
