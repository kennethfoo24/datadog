DD_APM_INSTRUMENTATION_ENABLED=docker DD_NO_AGENT_INSTALL=true bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_docker_injection.sh)" 

docker run -d --name dd-agent \
--cgroupns host \
--pid host \
-e DD_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
-e DD_SITE="datadoghq.com" \
-e DD_ENV=<ENV> \

# Enable APM
-e DD_APM_ENABLED=true \
-e DD_APM_NON_LOCAL_TRAFFIC=true \
-e DD_APM_RECEIVER_SOCKET=/opt/datadog/apm/inject/run/apm.socket \
-e DD_DOGSTATSD_SOCKET=/opt/datadog/apm/inject/run/dsd.socket \
-v /opt/datadog/apm:/opt/datadog/apm \

# Enable AppSec
-e DD_APPSEC_ENABLED=true \
-e DD_IAST_ENABLED=true \
-e DD_APPSEC_SCA_ENABLED \
-e DD_APM_NON_LOCAL_TRAFFIC=true \

# Enable Logs
-e DD_LOGS_ENABLED=true \
-e DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true \
-v /opt/datadog-agent/run:/opt/datadog-agent/run:rw \

# Enable Process Collection
-e DD_PROCESS_CONFIG_PROCESS_COLLECTION_ENABLED=true \
-v /etc/passwd:/etc/passwd:ro \

# Enable Network Performance Monitoring
-e DD_SYSTEM_PROBE_NETWORK_ENABLED=true \
-e DD_PROCESS_AGENT_ENABLED=true \

# Enable Cloud Security
-e DD_COMPLIANCE_CONFIG_ENABLED=true \
-e DD_COMPLIANCE_CONFIG_HOST_BENCHMARKS_ENABLED=true \
-e DD_RUNTIME_SECURITY_CONFIG_ENABLED=true \
-e DD_RUNTIME_SECURITY_CONFIG_REMOTE_CONFIGURATION_ENABLED=true \

# Enable Universal Service Monitoring
-e DD_SYSTEM_PROBE_SERVICE_MONITORING_ENABLED=true \
-v /lib/modules:/lib/modules:ro \
-v /usr/src:/usr/src:ro \
-v /var/tmp/datadog-agent/system-probe/build:/var/tmp/datadog-agent/system-probe/build \
-v /var/tmp/datadog-agent/system-probe/kernel-headers:/var/tmp/datadog-agent/system-probe/kernel-headers \
-v /etc/apt:/host/etc/apt:ro \
-v /etc/yum.repos.d:/host/etc/yum.repos.d:ro \
-v /etc/zypp:/host/etc/zypp:ro \
-v /etc/pki:/host/etc/pki:ro \
-v /etc/yum/vars:/host/etc/yum/vars:ro \
-v /etc/dnf/vars:/host/etc/dnf/vars:ro \
-v /etc/rhsm:/host/etc/rhsm:ro \

# Basic volumes needed
-v /var/run/docker.sock:/var/run/docker.sock:ro \
-v /proc/:/host/proc/:ro \
-v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
-v /var/lib/docker/containers:/var/lib/docker/containers:ro \

# Needed for Process Monitoring/Network Monitoring/Cloud Security
-e HOST_ROOT=/host/root \
-v /etc/group:/etc/group:ro \
-v /:/host/root:ro \
-v /sys/kernel/debug:/sys/kernel/debug \
-v /etc/os-release:/etc/os-release \
-v /sys/kernel/debug:/sys/kernel/debug \
--security-opt apparmor:unconfined \
--cap-add=SYS_ADMIN \
--cap-add=SYS_RESOURCE \
--cap-add=SYS_PTRACE \
--cap-add=NET_ADMIN \
--cap-add=NET_BROADCAST \
--cap-add=NET_RAW \
--cap-add=IPC_LOCK \
--cap-add=CHOWN \
gcr.io/datadoghq/agent:7
