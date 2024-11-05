
# Datadog Installation Script





## Usage
## Installation

#### Installing Datadog Agent (Windows)

```javascript
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kennethfoo24/datadog/refs/heads/main/datadog-setup-script/windows_host/monitoring_security.ps1')
```

#### Installing Datadog Agent (Linux)

```javascript
sudo bash -c "$(curl -L https://raw.githubusercontent.com/kennethfoo24/datadog/refs/heads/main/datadog-setup-script/linux_host/monitoring_security.sh)"
```


## Screenshots

![App Screenshot](https://ibb.co/y69cTkS)

![App Screenshot](https://ibb.co/2hD6QTm)



## Uninstallation

#### Uninstall Datadog (Windows)
Run Powershell as Administrator

```bash
$productCode = (@(Get-ChildItem -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse) | Where {$_.GetValue("DisplayName") -like "Datadog Agent" }).PSChildName
start-process msiexec -Wait -ArgumentList ('/log', 'C:\uninst.log', '/q', '/x', "$productCode", 'REBOOT=ReallySuppress')
```
    
#### Uninstall Datadog (Linux)

```bash
sudo apt-get remove datadog-agent -y \
sudo apt-get remove --purge datadog-agent -y
```
```bash
sudo yum remove datadog-agent \
sudo userdel dd-agent \
&& sudo rm -rf /opt/datadog-agent/ \
&& sudo rm -rf /etc/datadog-agent/ \
&& sudo rm -rf /var/log/datadog/
```
