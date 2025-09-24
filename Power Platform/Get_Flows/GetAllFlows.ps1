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
    Write-Progress -Activity "Processing Flows" -Status "Flow $Counter of $($Flows.Count): $($Flow.DisplayName)" -PercentComplete (($Counter / $Flows.Count) * 100)
    
    try {
        # First check if the initial flow data already has connector info
        $Connectors = $null
        if ($Flow.Internal.properties.connectionReferences) {
            $Connectors = $Flow.Internal.properties.connectionReferences
            Write-Verbose "Using connector info from initial flow data for $($Flow.DisplayName)"
        } else {
            # If not, try to get detailed flow info
            Write-Verbose "Getting detailed flow info for $($Flow.DisplayName)"
            $FlowInfo = Get-AdminFlow -FlowName $Flow.FlowName -EnvironmentName $Flow.EnvironmentName
            $Connectors = $FlowInfo.Internal.properties.connectionReferences
        }
        
        $UserId = $Flow.CreatedBy.UserID
        
        # Handle different types of creators (users, service principals, system accounts)
        if ($UserId -and $UserId -ne $null -and $UserId -ne "") {
            try {
                # First try as a user
                $User = Get-EntraUser -UserId $UserId -Property Id,DisplayName,UserPrincipalName
            }
            catch {
                try {
                    # If user lookup fails, try as service principal
                    $ServicePrincipal = Get-EntraServicePrincipal -ServicePrincipalId $UserId -Property Id,DisplayName,AppId
                    $User = @{ 
                        DisplayName = "$($ServicePrincipal.DisplayName) (Service Principal)"
                        UserPrincipalName = $ServicePrincipal.AppId 
                    }
                }
                catch {
                    Write-Warning "Failed to resolve creator $UserId for flow $($Flow.DisplayName): Not found as user or service principal"
                    $User = @{ 
                        DisplayName = "Unknown Creator"
                        UserPrincipalName = $UserId 
                    }
                }
            }
        }
        else {
            $User = @{ DisplayName = "System/Unknown"; UserPrincipalName = "N/A" }
        }
    }
    catch {
        Write-Warning "Failed to get detailed flow info for $($Flow.DisplayName): $($_.Exception.Message)"
        
        # Try to get connector info from the original flow object as fallback
        if ($Flow.Internal.properties.connectionReferences) {
            $Connectors = $Flow.Internal.properties.connectionReferences
            Write-Host "Using fallback connector info from original flow data" -ForegroundColor Yellow
        } else {
            $Connectors = $null
            Write-Warning "No connector information available for $($Flow.DisplayName) - neither detailed nor original flow data contains connectors"
        }
        
        $FlowInfo = $Flow
        $UserId = $Flow.CreatedBy.UserID
        $User = @{ DisplayName = "Unknown"; UserPrincipalName = "Unknown" }
    }
    
    # Create base object
    $FlowObject = [PSCustomObject]@{
        FlowID = $Flow.FlowName
        FlowName = $Flow.DisplayName
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
    
    # Add small delay to avoid rate limiting in large environments
    if ($Flows.Count -gt 50 -and $Counter % 10 -eq 0) {
        Start-Sleep -Seconds 1
    }
}

# Ensure all objects have the same properties for CSV export
$MaxConnectors = 0
foreach ($Flow in $FlowData) {
    $ConnectorCount = ($Flow.PSObject.Properties.Name | Where-Object { $_ -match "Connector\d+" }).Count
    if ($ConnectorCount -gt $MaxConnectors) { $MaxConnectors = $ConnectorCount }
} 

# Add missing connector columns to all flows
foreach ($Flow in $FlowData) {
    for ($i = 1; $i -le $MaxConnectors; $i++) {
        $PropName = "Connector$i"
        if (-not ($Flow.PSObject.Properties.Name -contains $PropName)) {
            $Flow | Add-Member -NotePropertyName $PropName -NotePropertyValue ""
        }
    }
}

# Export to CSV - handles all escaping automatically
$FlowData | Export-Csv -Path $FilePath -NoTypeInformation

# Show summary statistics
$FlowsWithConnectors = ($FlowData | Where-Object { $_.PSObject.Properties.Name -match "Connector\d+" -and $_.PSObject.Properties.Value -ne "" }).Count
Write-Host "Export completed: $FilePath" -ForegroundColor Green
Write-Host "Summary: $($FlowData.Count) flows processed, $FlowsWithConnectors flows have connector information, $MaxConnectors max connectors per flow" -ForegroundColor Cyan
Disconnect-Entra
Write-Host "Disconnected from Entra"
Write-Host "Script completed." -ForegroundColor Green
Remove-PowerAppsAccount
Write-Host "Disconnected from PowerApps"