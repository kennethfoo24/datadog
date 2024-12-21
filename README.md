
# Datadog Installation Script (Host-based Setup)





## Usage
## Installation

#### Installing Datadog Agent (Windows)
Run Powershell as Administrator

```shell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser Invoke-Expression 
(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/kennethfoo24/datadog/refs/heads/main/datadog-setup-script/windows_host/monitoring_security.ps1')
```

#### Installing Datadog Agent (Linux)

```javascript
sudo bash -c "$(curl -L https://raw.githubusercontent.com/kennethfoo24/datadog/refs/heads/main/datadog-setup-script/linux_host/monitoring_security.sh)"
```


## Screenshots

![App Screenshot](https://i.ibb.co/4t6fGH9/Screenshot-2024-11-05-at-6-56-46-PM.png)

![App Screenshot](https://i.ibb.co/6HM7htB/Screenshot-2024-11-05-at-6-54-37-PM.png)



## Uninstallation

#### Uninstall Datadog (Windows)
Run Powershell as Administrator

```bash
$productCode = (@(Get-ChildItem -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse) | Where {$_.GetValue("DisplayName") -like "Datadog Agent" }).PSChildName start-process msiexec -Wait -ArgumentList ('/log', 'C:\uninst.log', '/q', '/x', "$productCode", 'REBOOT=ReallySuppress')
```
    
#### Uninstall Datadog (Linux)

```bash
sudo apt-get remove datadog-agent -y \
dd-host-install --uninstall \
sudo apt-get remove --purge datadog-agent -y \
```
```bash
sudo yum remove datadog-agent \
dd-host-install --uninstall \
sudo userdel dd-agent \
&& sudo rm -rf /opt/datadog-agent/ \
&& sudo rm -rf /etc/datadog-agent/ \
&& sudo rm -rf /var/log/datadog/
```
