# datadog

# Windows
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kennethfoo24/datadog/refs/heads/main/datadog-setup-script/windows_host/monitoring_security.ps1')

# Linux
sudo bash -c "$(curl -L https://raw.githubusercontent.com/kennethfoo24/datadog/refs/heads/main/datadog-setup-script/linux_host/monitoring_security.sh)"
