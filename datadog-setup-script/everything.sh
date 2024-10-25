#!/bin/bash

# This script installs the Datadog Agent with everything enabled,
# collects logs from all directories containing .log files,
# and updates permissions for all .log files.

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

# Prompt for service name 
read -p "Enter the name your application service (eg: my-app-service) [default_service]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-default_service}

# Prompt for source name 
read -p "Enter the source of your application service (eg: nodejs,dotnet) [default_source]: " SOURCE_NAME
SOURCE_NAME=${SOURCE_NAME:-default_source}

# Prompt for env name 
read -p "Enter the environment of your service (eg: production,staging) [default_env]: " ENV_NAME
ENV_NAME=${ENV_NAME:-default_env}

# Install the Datadog Agent using the installation link
DD_API_KEY="$DD_API_KEY" DD_ENV="$ENV_NAME" DD_APM_INSTRUMENTATION_ENABLED=host DD_TRACE_DEBUG=true DD_LOGS_INJECTION=true DD_TRACE_SAMPLE_RATE="1" DD_RUNTIME_METRICS_ENABLED=true DD_PROFILING_ENABLED=true DD_APPSEC_ENABLED=true DD_IAST_ENABLED=true DD_APPSEC_SCA_ENABLED=true DD_RUNTIME_SECURITY_CONFIG_ENABLED=true DD_SBOM_CONTAINER_IMAGE_ENABLED=true DD_SBOM_HOST_ENABLED=true bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"

# Append custom configuration to the datadog.yaml file
echo "Appending custom configuration to /etc/datadog-agent/datadog.yaml..."

cat <<EOF >> /etc/datadog-agent/datadog.yaml

## Custom Configuration Appended by Script

## Official Source: https://github.com/DataDog/datadog-agent/blob/main/pkg/config/config_template.yaml
##
## Edit this in file location :
## Linux: /etc/datadog-agent/datadog.yaml
## Windows: %ProgramData%\Datadog\datadog.yaml
api_key: $DD_API_KEY
site: $DD_SITE
env: $ENV_NAME

## Tags https://docs.datadoghq.com/tagging/
# tags:
#   - team:infra
#   - <TAG_KEY>:<TAG_VALUE>

## Logs 
logs_enabled: true
logs_config:
  container_collect_all: true
  auto_multi_line_detection: true

## APM
apm_config:
  enabled: true

## Process Monitoring
process_config:
  process_collection:
    enabled: true

## Cloud Security Posture Management
compliance_config:
  enabled: true
  host_benchmarks:
    enabled: true

## Cloud Workload Security
runtime_security_config:
  enabled: true

## Remote Configuration
remote_configuration:
  enabled: true

## SBOM + CSM(container,host) Vulnerabilities (CSM Pro) (Only Linux)
sbom:
  enabled: true
  container_image:
    enabled: true
  host:
    enabled: true
container_image:
  enabled: true
  
## OTLP
otlp_config:
  logs:
    enabled: true
  receiver:
    protocols:
      grpc:
        endpoint: localhost:4317
      http:
        endpoint: localhost:4318

EOF

# Append custom configuration to the security-agent.yaml file
echo "Appending custom configuration to /etc/datadog-agent/security-agent.yaml..."

cat <<EOF >> /etc/datadog-agent/security-agent.yaml

## Custom Configuration Appended by Script

# CWS
runtime_security_config: 
  enabled: true

# CSPM
compliance_config:
  enabled: true
  host_benchmarks:
    enabled: true

EOF

# Append custom configuration to the system-probe.yaml file
echo "Appending custom configuration to /etc/datadog-agent/system-probe.yaml..."

cat <<EOF >> /etc/datadog-agent/system-probe.yaml

## Universal Service Monitoring
service_monitoring_config:
  enabled: true
  process_service_inference:
    enabled: true

## Network Performance Monitoring
network_config:
  enabled: true

## Process Monitoring I/O Stats
system_probe_config:
  process_config:
    enabled: true

## Cloud Security Management
runtime_security_config: 
  enabled: true
  remote_configuration:
    enabled: true

EOF

# Configure the Agent to collect all .log files on the system
mkdir -p /etc/datadog-agent/conf.d/all_logs.d

cat <<EOF > /etc/datadog-agent/conf.d/all_logs.d/conf.yaml
logs:
  - type: file
    path: "*.log"
    service: $SERVICE_NAME
    source: $SOURCE_NAME
  - type: file
    path: /*.log
    service: $SERVICE_NAME
    source: $SOURCE_NAME
  - type: file
    path: /**/*.log
    service: $SERVICE_NAME
    source: $SOURCE_NAME
  - type: file
    path: /*/**/*.log
    service: $SERVICE_NAME
    source: $SOURCE_NAME
  - type: file
    path: /*/**/**/*.log
    service: $SERVICE_NAME
    source: $SOURCE_NAME
  - type: file
    path: /*/**/**/**/*.log
    service: $SERVICE_NAME
    source: $SOURCE_NAME
EOF

# Update permissions for all .log files
echo "Updating permissions for all .log files..."

find / -type f -name "*.log" 2>/dev/null | while read -r logfile; do
    chmod o+r "$logfile"
done

# Restart the Datadog Agent to apply changes
systemctl restart datadog-agent

echo "Datadog Agent installation and configuration complete."
