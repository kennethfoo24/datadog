# Prompt for Datadog site selection
Write-Host "Select your Datadog site:"
Write-Host "1) US1 (Datadog US1)"
Write-Host "2) US3 (Datadog US3)"
Write-Host "3) US5 (Datadog US5)"
Write-Host "4) EU1 (Datadog EU)"
Write-Host "5) US1-FED (Datadog US1 Federal)"
Write-Host "6) AP1 (Datadog AP1)"

$SITE_SELECTION = Read-Host "Enter the number corresponding to your site [1]:"
if ([string]::IsNullOrEmpty($SITE_SELECTION)) {
    $SITE_SELECTION = "1"
}

# Map the selection to the site parameter
switch ($SITE_SELECTION) {
    "1" { $DD_SITE = "datadoghq.com" }
    "2" { $DD_SITE = "us3.datadoghq.com" }
    "3" { $DD_SITE = "us5.datadoghq.com" }
    "4" { $DD_SITE = "datadoghq.eu" }
    "5" { $DD_SITE = "ddog-gov.com" }
    "6" { $DD_SITE = "ap1.datadoghq.com" }
    default {
        Write-Host "Invalid selection. Defaulting to US1 (datadoghq.com)."
        $DD_SITE = "datadoghq.com"
    }
}

Write-Host "Selected Datadog site: $DD_SITE"

# Prompt for Datadog API key
$apiKey = Read-Host "Enter your Datadog API key"

# Prompt for Service Name
$serviceName = Read-Host "Enter the name your application service (eg: my-app-service) [default_service]: "
if ([string]::IsNullOrEmpty($serviceName)) {
    $serviceName = "default_service"
}

# Prompt for Source Name
$sourceName = Read-Host "Enter the source of your application service (eg: nodejs,dotnet) [default_source]: "
if ([string]::IsNullOrEmpty($sourceName)) {
    $sourceName = "default_source"
}

# Prompt for Environment Name
$environmentName = Read-Host "Enter the environment of your service (eg: production,staging) [default_env]: "
if ([string]::IsNullOrEmpty($environmentName)) {
    $environmentName = "default_env"
}

# Construct tags from input
$tags = "service:$serviceName,source:$sourceName,env:$environmentName"

# Step 3: Install the Datadog Agent
Write-Host "Installing Datadog Agent"
Start-Process -Wait msiexec -ArgumentList '/qn /i "https://s3.amazonaws.com/ddagent-windows-stable/datadog-agent-7-latest.amd64.msi" APIKEY=`"$apiKey`" SITE=`"$DD_SITE`" TAGS=`"$tags`" '

# Step 4: Configure the Datadog Agent
Write-Host "Configuring Datadog Agent"
$configFile = "C:\ProgramData\Datadog\datadog.yaml"

# Check if the configuration file exists
if (Test-Path $configFile) {
    $configContent = Get-Content $configFile
} else {
    $configContent = @()
    New-Item -Path $configFile -ItemType File -Force
}

# Update the datadog.yaml file with the provided content

# Path to the datadog.yaml file
Write-Host "Updating datadog.yaml file"
$configFile = "C:\ProgramData\Datadog\datadog.yaml"

# Content to write to datadog.yaml
$yamlContent = @"
## Official Source: https://github.com/DataDog/datadog-agent/blob/main/pkg/config/config_template.yaml
##
## Edit this in file location :
## Linux: /etc/datadog-agent/datadog.yaml
## Windows: %ProgramData%\Datadog\datadog.yaml
api_key: $apiKey
site: $DD_SITE
env: $environmentName

## Tags https://docs.datadoghq.com/tagging/
tags:
  - service: $serviceName
  - source: $sourceName
  - env: $environmentName

## Logs 
logs_enabled: true
logs_config:
  auto_multi_line_detection: true

## APM
apm_config:
  enabled: true

## Process Monitoring
process_config:
  process_collection:
    enabled: true

## Remote Configuration
remote_configuration:
  enabled: true

## OTLP
otlp_config:
  receiver:
    protocols:
      grpc:
        endpoint: localhost:4317
      http:
        endpoint: localhost:4318
  logs:
    enabled: true

## Host Vulnerability Scanning
sbom:
  enabled: true
  host:
    enabled: true

## If using Windows EC2 Auto Scaling Group https://docs.datadoghq.com/agent/faq/ec2-use-win-prefix-detection/ 
ec2_use_windows_prefix_detection: true
"@

# Write the content to the datadog.yaml file
$yamlContent | Set-Content -Path $configFile -Encoding UTF8

# Update the security-agent.yaml file with the provided content

# Path to the security-agent.yaml file
Write-Host "Updating security-agent.yaml file"
$securityConfigFile = "C:\ProgramData\Datadog\security-agent.yaml"

# Content to write to security-agent.yaml
$securityYamlContent = @"
runtime_security_config:
  enabled: true
  # File Integrity Monitoring (FIM)
  fim_enabled: true
"@

# Write the content to the security-agent.yaml file
$securityYamlContent | Set-Content -Path $securityConfigFile -Encoding UTF8

# Update the system-probe.yaml file with the provided content

# Path to the system-probe.yaml file
Write-Host "Updating system-probe.yaml file"
$systemprobeConfigFile = "C:\ProgramData\Datadog\system-probe.yaml"

# Content to write to system-probe.yaml
$systemprobeYamlContent = @"
## Universal Service Monitoring
service_monitoring_config:
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
  # File Integrity Monitoring (FIM)
  fim_enabled: true
"@

# Write the content to the system-probe.yaml file
$systemprobeYamlContent | Set-Content -Path $systemprobeConfigFile -Encoding UTF8

# Step 5: Restart the Datadog Agent Service
Write-Host "Restarting Datadog Agent Service"
Restart-Service -Name "datadogagent"
