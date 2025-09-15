Write-Host "This tool is used to retrieve all flows in all environments in the tenant, or the flows the user has access to" -ForegroundColor Green

$InstallModules = Read-Host "Do you want to install the required modules? (Y/N)"
if ($InstallModules -eq "Y") {
    Write-Host "Installing required modules..." -ForegroundColor Green
    Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -AllowClobber -Force
} else {
    Write-Host "Skipping module installation..." -ForegroundColor Yellow
}

Add-PowerAppsAccount

$Environments = Get-AdminPowerAppEnvironment
$AllFlows = @()
foreach ($Environment in $Environments) {
    Write-Host "Retrieving flows for environment: $($Environment.DisplayName)" -ForegroundColor Green
    $Flows = Get-AdminFlow -EnvironmentName $Environment.EnvironmentName
    $AllFlows += $Flows
}