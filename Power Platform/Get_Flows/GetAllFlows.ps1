Write-Host "This tool is used to retrieve all flows in all environments in the tenant, or the flows the user has access to" -ForegroundColor Green

$InstallModules = Read-Host "Do you want to install the required modules? (Y/N)"
if ($InstallModules -eq "Y") {
    Write-Host "Installing required modules..." -ForegroundColor Green
    Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -AllowClobber -Force
    Install-Module -Name Microsoft.Entra -AllowClobber -Force
} else {
    Write-Host "Skipping module installation..." -ForegroundColor Yellow
}

Add-PowerAppsAccount
Connect-Entra -Scopes 'User.Read.All'
$FilePath = "./FlowsExport.csv"
$Flows = Get-AdminFlow
$FlowData = @()

Write-Host "Processing $($Flows.Count) flows..."
$Counter = 0

ForEach ($Flow in $Flows) {
    $Counter++
    
    $FlowInfo = Get-AdminFlow -FlowName $Flow.FlowName -EnvironmentName $Flow.EnvironmentName
    $Connectors = $FlowInfo.Internal.properties.connectionReferences
    $UserId = $FlowInfo.CreatedBy.UserID  # Replace with actual user ID
    $User = Get-EntraUser -UserId $UserId -Property Id,DisplayName,UserPrincipalName
    
    # Create base object
    $FlowObject = [PSCustomObject]@{
        Name = $Flow.DisplayName
        Enabled = $Flow.Enabled
        Environment = $Flow.EnvironmentName
        UserID = $FlowInfo.CreatedBy.UserID
        UserDisplayName = $User.DisplayName
        UserPrincipalName = $User.UserPrincipalName
    }
    
    # Add connector columns dynamically
    if ($Connectors) {
        $ConnectorIndex = 1
        $Connectors.PSObject.Properties | ForEach-Object {
            if ($_.Value.DisplayName) {
                $FlowObject | Add-Member -NotePropertyName "Connector$ConnectorIndex" -NotePropertyValue $_.Value.DisplayName
                $ConnectorIndex++
            }
        }
    }
    
    $FlowData += $FlowObject
}

# Export to CSV - handles all escaping automatically
$FlowData | Export-Csv -Path $FilePath -NoTypeInformation
Write-Host "Export completed: $FilePath"
Disconnect-Entra
Write-Host "Disconnected from Entra"
Write-Host "Script completed." -ForegroundColor Green
Remove-PowerAppsAccount
Write-Host "Disconnected from PowerApps"