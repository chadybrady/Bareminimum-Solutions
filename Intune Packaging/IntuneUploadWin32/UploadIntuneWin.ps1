Write-Host "## This script is used to upload a Win32 app to Intune using the Microsoft Graph API."
Write-Host "##Created by LJ Hjort, 2025"

#Installs the module
Install-Module -Name "IntuneWin32App" -AcceptLicense
# Import required module
Import-Module Microsoft.Graph.Intune

$TenantID = Read-Host "Enter you Tenant ID:"
Connect-MSIntuneGraph -TenantID $TenantID 