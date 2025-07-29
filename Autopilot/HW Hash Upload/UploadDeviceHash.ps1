#Created By Tim Hjort 2025
#User is required to have atleast intune administrator rights to run this script.

#Sets the security protocol to TLS 1.2 for secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Sets Execution Policy for the current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

#Installs the Get-WindowsAutopilotInfo script
Install-Script -Name Get-WindowsAutopilotInfo -Force

# Retrieves the Windows Autopilot information and prompts for user credentials
Get-WindowsAutopilotInfo -Online



