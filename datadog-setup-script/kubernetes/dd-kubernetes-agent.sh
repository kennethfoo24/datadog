#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script as root or with sudo."
   exit 1
fi

# Prompt for Datadog site selection
echo "Select your Datadog site:"
echo "1) US1 (Datadog US1)"
echo "2) US3 (Datadog US3)"
echo "3) US5 (Datadog US5)"
echo "4) EU1 (Datadog EU)"
echo "5) US1-FED (Datadog US1 Federal)"
echo "6) AP1 (Datadog AP1)"

read -p "Enter the number corresponding to your site [1]: " SITE_SELECTION
SITE_SELECTION=${SITE_SELECTION:-1}

# Map the selection to the site parameter
case "$SITE_SELECTION" in
    1)
        DD_SITE="datadoghq.com"
        ;;
    2)
        DD_SITE="us3.datadoghq.com"
        ;;
    3)
        DD_SITE="us5.datadoghq.com"
        ;;
    4)
        DD_SITE="datadoghq.eu"
        ;;
    5)
        DD_SITE="ddog-gov.com"
        ;;
    6)
        DD_SITE="ap1.datadoghq.com"
        ;;
    *)
        echo "Invalid selection. Defaulting to US1 (datadoghq.com)."
        DD_SITE="datadoghq.com"
        ;;
esac

echo "Selected Datadog site: $DD_SITE"

# Prompt for Datadog API key if not already set
if [ -z "$DD_API_KEY" ]; then
    read -p "Enter your Datadog API key: " DD_API_KEY
    if [ -z "$DD_API_KEY" ]; then
        echo "Datadog API key is required."
        exit 1
    fi
fi

# Prompt for cluster name 
read -p "Enter the name of your kubernetes cluster (eg: my-k8s-cluster) [default_cluster]: " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-default_cluster}

# Prompt for namespace name
read -p "Enter the namespace to install the Datadog Agent (default: datadog-agent): " DATADOG_NAMESPACE
DATADOG_NAMESPACE=${DATADOG_NAMESPACE:-datadog-agent}

# Prompt for env name 
read -p "Enter the environment of your service (eg: production,staging) [default_env]: " ENV_NAME
ENV_NAME=${ENV_NAME:-default_env}

# Variables - Update these as needed
DATADOG_SECRET_NAME="datadog-secret"
DATADOG_CONFIG_FILE="datadog-agent.yaml"

# Function to install Helm if the user agrees
install_helm() {
  echo "Helm is required but not installed."
  read -p "Would you like to install Helm? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  else
    echo "Helm installation canceled. Exiting."
    exit 1
  fi
}

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
  install_helm
fi

# Step 1: Create the specified namespace if it doesn't already exist
echo "Creating the '$DATADOG_NAMESPACE' namespace..."
kubectl get namespace "$DATADOG_NAMESPACE" &> /dev/null || kubectl create namespace "$DATADOG_NAMESPACE"

# Step 1: Add the Datadog Helm repository and install the Datadog operator
echo "Adding Datadog Helm repository..."
helm repo add datadog https://helm.datadoghq.com
helm repo update
echo "Installing Datadog Operator in the '$DATADOG_NAMESPACE' namespace..."
helm install datadog-operator datadog/datadog-operator --namespace "$DATADOG_NAMESPACE"

# Step 1: Create Datadog API Key Secret in Kubernetes
echo "Creating Datadog API key secret..."
kubectl create secret generic "$DATADOG_SECRET_NAME" --namespace "$DATADOG_NAMESPACE" --from-literal=api-key="$DATADOG_API_KEY" --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Create the Datadog agent configuration YAML
echo "Creating Datadog agent configuration file..."
cat <<EOF > "$DATADOG_CONFIG_FILE"
apiVersion: "datadoghq.com/v2alpha1"
kind: "DatadogAgent"
metadata:
  name: "datadog"
  namespace: "$DATADOG_NAMESPACE"
spec:
  global:
    clusterName: "$CLUSTER_NAME"
    registry: "gcr.io/datadoghq"
    site: "$DD_SITE"
    tags:
      - "env:$ENV_NAME"
    credentials:
      apiSecret:
        secretName: "$DATADOG_SECRET_NAME"
        keyName: "api-key"
  features:
    apm:
      instrumentation:
        enabled: true
        libVersions:
          java: "1"
          dotnet: "3"
          python: "2"
          js: "5"
          ruby: "2"
    logCollection:
      enabled: true
      containerCollectAll: true
    liveProcessCollection:
      enabled: true
    liveContainerCollection:
      enabled: true
    processDiscovery:
      enabled: true
    oomKill:
      enabled: true
    tcpQueueLength:
      enabled: true
    ebpfCheck:
      enabled: true
    asm:
      threats:
        enabled: true
      sca:
        enabled: true
      iast:
        enabled: true
    cws:
      enabled: true
    cspm:
      enabled: true
    sbom:
      containerImage:
        enabled: true
      host:
        enabled: true
    usm:
      enabled: true
    npm:
      enabled: true
    remoteConfiguration:
      enabled: true
    eventCollection:
      collectKubernetesEvents: true
    orchestratorExplorer:
      enabled: true
    kubeStateMetricsCore:
      enabled: true
    admissionController:
      enabled: true
    externalMetricsServer:
      enabled: true
    clusterChecks:
      enabled: true
    prometheusScrape:
      enabled: true
    otlp:
      receiver:
        protocols:
          grpc:
            enabled: true
          http:
            enabled: true
EOF

# Step 3: Apply the Datadog agent configuration
echo "Applying Datadog agent configuration in the '$DATADOG_NAMESPACE' namespace..."
kubectl apply -f "$DATADOG_CONFIG_FILE" --namespace "$DATADOG_NAMESPACE"

# Step 6: Display created resources
echo "Displaying resources created in the '$DATADOG_NAMESPACE' namespace..."

echo "1. Datadog Operator:"
kubectl get deployments -n "$DATADOG_NAMESPACE" -l "app.kubernetes.io/name=datadog-operator"

echo "2. Datadog API Key Secret:"
kubectl get secret "$DATADOG_SECRET_NAME" -n "$DATADOG_NAMESPACE"

echo "3. DatadogAgent Custom Resource:"
kubectl get datadogagent -n "$DATADOG_NAMESPACE"

echo "Datadog Agent installation complete."
