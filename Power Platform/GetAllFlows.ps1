#Created by Tim hjort 2025
#Used to gather all flows in a tenant from each environment.

$requiredModules = @(
    'Microsoft.PowerApps.Administration.PowerShell',
    'Microsoft.PowerApps.PowerShell'
)

foreach ($module in $requiredModules) {
    try {
        if (-not (Get-Module -Name $module -ListAvailable)) {
            Write-Host "Installing module: $module"
            Install-Module -Name $module -Force -Scope CurrentUser -ErrorAction Stop -AllowClobber
        } else {
            Write-Host "Module $module is already installed."
        }

        # Check if the module is already imported
        if (-not (Get-Module -Name $module)) {
            # Import the module
            Import-Module $module -ErrorAction Stop
            Write-Host "Module $module has been imported."
        } else {
            Write-Host "Module $module is already imported."
        }
    } catch {
        Write-Error "Failed to install or import module $module : $_"
    }
}

##Adds Powerappsaccount and prompts for user and password from the user
$UsersUserName = Read-Host "Enter your Username"
$UsersPassword = Read-Host "Enter your password" -AsSecureString
##Connects to the Powerapps modules
Add-PowerAppsAccount -Username $UsersUserName -Password $UsersPassword

# Get all environments
$environments = Get-AdminPowerAppEnvironment

# Initialize counters
$totalFlows = 0
$enabledFlows = 0
$disabledFlows = 0

foreach ($env in $environments) {
    $flows = Get-AdminFlow -EnvironmentName $env.EnvironmentName
    $totalFlows += $flows.Count
    $enabledFlows += ($flows | Where-Object { $_.Properties.state -eq "Started" }).Count
    $disabledFlows += ($flows | Where-Object { $_.Properties.state -eq "Stopped" }).Count
}

Write-Host "Total flows: $totalFlows"
Write-Host "Enabled flows: $enabledFlows"
Write-Host "Disabled flows: $disabledFlows"

    # Cleanup: Uninstall modules
foreach ($module in $requiredModules) {
    try {
        # First remove the module from the current session
        if (Get-Module -Name "$module*") {
            Write-Host "Removing module from current session: $module"
            Remove-Module -Name "$module*" -Force -ErrorAction Stop
        }

        # Then uninstall all versions of the module and its submodules
        $moduleVersions = Get-Module -Name "$module*" -ListAvailable
        foreach ($version in $moduleVersions) {
            Write-Host "Uninstalling module: $($version.Name) version $($version.Version)"
            Uninstall-Module -Name $version.Name -RequiredVersion $version.Version -Force -ErrorAction Stop
        }
        
        Write-Host "Module $module and its components have been completely removed" -ForegroundColor Green
    } catch {
        Write-Error "Failed to remove/uninstall module $module : $_"
    }
}