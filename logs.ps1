# Define the path to the log file
$logFilePath = "C:\Logs\log\mylog.log"

# Ensure the Logs directory exists
if (!(Test-Path -Path "C:\Logs\log")) {
    New-Item -ItemType Directory -Path "C:\Logs\log"
}

# Function to write logs
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    # Append the log entry to the log file
    Add-Content -Path $logFilePath -Value $LogEntry
}

# Continuous logging loop
while ($true) {
    Write-Log -Message "Logging at regular intervals."
    # Wait for a specified time interval (e.g., 1 seconds)
    Start-Sleep -Seconds 1
}
