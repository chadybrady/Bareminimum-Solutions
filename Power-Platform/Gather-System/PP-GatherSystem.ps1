#Install-Module -Name Microsoft.PowerApps.Administration.PowerShell
#Install-Module -Name Microsoft.PowerApps.PowerShell -AllowClobber

<#
.SYNOPSIS
    Combined Power Platform Export Script
.DESCRIPTION
    Exports both Power Apps and Power Automate flows with their connectors from all environments
.NOTES
    Author: Power Platform Admin
    Version: 1.0
    Date: $(Get-Date -Format 'yyyy-MM-dd')
#>

# 1. Connect and login to Power Platform automatically
Write-Host "Connecting to Power Platform..." -ForegroundColor Green
try {
    Add-PowerAppsAccount -ErrorAction Stop
    Write-Host "Successfully connected to Power Platform!" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Power Platform. Please ensure you have the necessary permissions."
    exit 1
}

# 2. Get all environments automatically
Write-Host "Gathering all environments..." -ForegroundColor Green
try {
    $Environments = Get-PowerAppEnvironment | Select-Object -Property EnvironmentName, DisplayName
    Write-Host "Found $($Environments.Count) environments" -ForegroundColor Green
} catch {
    Write-Error "Failed to retrieve environments. Error: $($_.Exception.Message)"
    exit 1
}

# 3. Set export paths to same folder as script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$PowerAppsCSVPath = Join-Path -Path $ScriptPath -ChildPath "PowerAppsExport_$Timestamp.csv"
$PowerAutomateCSVPath = Join-Path -Path $ScriptPath -ChildPath "PowerAutomateExport_$Timestamp.csv"
$CombinedCSVPath = Join-Path -Path $ScriptPath -ChildPath "PowerPlatformCombined_$Timestamp.csv"
$SummaryCSVPath = Join-Path -Path $ScriptPath -ChildPath "ConnectorSummary_$Timestamp.csv"

Write-Host "Export paths:" -ForegroundColor Yellow
Write-Host "   Power Apps: $PowerAppsCSVPath" -ForegroundColor Gray
Write-Host "   Power Automate: $PowerAutomateCSVPath" -ForegroundColor Gray
Write-Host "   Combined: $CombinedCSVPath" -ForegroundColor Gray
Write-Host "   Summary: $SummaryCSVPath" -ForegroundColor Gray
Write-Host ""

# Simple tier assignment function
function Get-ConnectorTier($ConnectorName) {
    switch -Regex ($ConnectorName) {
        "^Office 365" { return "Standard" }
        "^SharePoint" { return "Standard" }
        "^Microsoft Dataverse" { return "Standard" }
        "^Microsoft Teams" { return "Standard" }
        "^OneDrive" { return "Standard" }
        "^Planner" { return "Standard" }
        "^RSS" { return "Standard" }
        "^HTTP" { return "Standard" }
        "^Mail$" { return "Standard" }
        "^Approvals" { return "Standard" }
        "^Azure AD" { return "Standard" }
        "^Power BI" { return "Standard" }
        "^SQL" { return "Premium" }
        "^Oracle" { return "Premium" }
        "^Salesforce" { return "Premium" }
        "^FTP" { return "Premium" }
        "^SFTP" { return "Premium" }
        default { return "Standard" }
    }
}

########################### POWER APPS EXPORT #####################################
Write-Host "Starting Power Apps data collection..." -ForegroundColor Magenta

$PowerAppsReport = [System.Collections.Generic.List[Object]]::new()
$AppsProgressCount = 0
$TotalEnvironments = $Environments.Count
$CurrentEnvCount = 0

# Loop through all Environments for Power Apps
foreach ($Environment in $Environments)
{
    $CurrentEnvCount++
    Write-Host "Processing Environment $CurrentEnvCount of $TotalEnvironments : $($Environment.DisplayName)" -ForegroundColor Cyan
    
    try {
        # List all Apps in each environment
        $AppNames = Get-AdminPowerApp -EnvironmentName $Environment.EnvironmentName | Select-Object -Property AppName, DisplayName, Owner, CreatedTime, LastModifiedTime
        $AppsDataCount = ($AppNames | Measure-Object).Count
        Write-Host "   Found $AppsDataCount apps" -ForegroundColor Yellow

        $LocalAppCount = 0
        # Loop through each app to get connectors it is using
        foreach ($AppName in $AppNames) 
        {
            try {
                $AppsProgressCount++
                $LocalAppCount++
                $PercentComplete = if ($AppsDataCount -gt 0) { [Math]::Min(100, ($LocalAppCount / $AppsDataCount) * 100) } else { 100 }
                Write-Progress -Activity "Gathering Power Apps from all environments" -Id 1 -Status "Env: $($Environment.DisplayName) | App: $LocalAppCount / $AppsDataCount" -CurrentOperation $("Processing: $($AppName.DisplayName)") -PercentComplete $PercentComplete
                
                $Connectors = Get-AdminPowerAppConnectionReferences -EnvironmentName $Environment.EnvironmentName -AppName $AppName.AppName | Select-Object -Property Displayname, Tier

                # Clean and format connector data
                $ConnectorNames = @()
                $ConnectorTiers = @()
                
                foreach ($Connector in $Connectors) {
                    if ($Connector.Displayname -and $Connector.Displayname.Trim() -ne "") {
                        $ConnectorNames += $Connector.Displayname.Trim()
                        $ConnectorTiers += if ($Connector.Tier) { $Connector.Tier.Trim() } else { "Unknown" }
                    }
                }

                $ReportLine = [PSCustomObject]@{
                    Type                  = "PowerApp"
                    ItemId                = $AppName.AppName
                    ItemName              = $AppName.DisplayName
                    Owner                 = $AppName.Owner.userPrincipalName
                    EnvironmentId         = $Environment.EnvironmentName
                    EnvironmentName       = $Environment.DisplayName
                    Enabled               = "N/A"
                    Connectors            = if ($ConnectorNames.Count -gt 0) { $ConnectorNames -join "; " } else { "None" }
                    ConnectorTiers        = if ($ConnectorTiers.Count -gt 0) { $ConnectorTiers -join "; " } else { "N/A" }
                    LastModifiedTime      = $AppName.LastModifiedTime
                    CreatedTime           = $AppName.CreatedTime
                }

                $PowerAppsReport.Add($ReportLine)
            } catch {
                Write-Warning "Failed to process app: $($AppName.DisplayName). Error: $($_.Exception.Message)"
            }
        }
    } catch {
        Write-Warning "Failed to process environment: $($Environment.DisplayName) for Power Apps. Error: $($_.Exception.Message)"
    }
}

Write-Host "Power Apps collection completed: $($PowerAppsReport.Count) records" -ForegroundColor Green
Write-Host ""

########################### POWER AUTOMATE EXPORT #####################################
Write-Host "Starting Power Automate data collection..." -ForegroundColor Blue

$PowerAutomateReport = [System.Collections.Generic.List[Object]]::new()
$FlowsProgressCount = 0
$CurrentEnvCount = 0

# Loop through all Environments for Power Automate
foreach ($Environment in $Environments)
{
    $CurrentEnvCount++
    Write-Host "Processing Environment $CurrentEnvCount of $TotalEnvironments : $($Environment.DisplayName)" -ForegroundColor Cyan
    
    try {
        # List all Flows in each environment
        $FlowNames = Get-AdminFlow -EnvironmentName $Environment.EnvironmentName
        $FlowsDataCount = ($FlowNames | Measure-Object).Count
        Write-Host "   Found $FlowsDataCount flows" -ForegroundColor Yellow

        $LocalFlowCount = 0
        # Loop through each flow to get connectors it is using
        foreach ($FlowName in $FlowNames) 
        {
            try {
                $Connectorslist = Get-AdminFlow -FlowName $FlowName.FlowName -EnvironmentName $Environment.EnvironmentName
                
                # Get owner information directly from the flow object
                $OwnerPrincipalName = if ($FlowName.CreatedBy.userPrincipalName) {
                    $FlowName.CreatedBy.userPrincipalName
                } elseif ($FlowName.CreatedBy.email) {
                    $FlowName.CreatedBy.email
                } else {
                    $FlowName.CreatedBy.userId
                }
            
                $FlowsProgressCount++
                $LocalFlowCount++
                $PercentComplete = if ($FlowsDataCount -gt 0) { [Math]::Min(100, ($LocalFlowCount / $FlowsDataCount) * 100) } else { 100 }
                Write-Progress -Activity "Gathering Power Automate flows from all environments" -Id 2 -Status "Env: $($Environment.DisplayName) | Flow: $LocalFlowCount / $FlowsDataCount" -CurrentOperation $("Processing: $($FlowName.DisplayName)") -PercentComplete $PercentComplete

                # Collect all connectors for this flow - simplified approach
                $AllConnectors = @()

                try {
                    # Method 1: Try to get connector info from connection references
                    if ($Connectorslist.Internal.properties.connectionReferences) {
                        $connectionReferences = $Connectorslist.Internal.properties.connectionReferences
                        foreach ($connRef in $connectionReferences.PSObject.Properties) {
                            $connDetails = $connRef.Value
                            if ($connDetails.displayName) {
                                $connectorName = [string]$connDetails.displayName
                                if ($connectorName -and $connectorName.Trim() -ne "") {
                                    $AllConnectors += $connectorName.Trim()
                                }
                            }
                        }
                    }

                    # Method 2: Try to extract from definition summary if no connection references found
                    if ($AllConnectors.Count -eq 0 -and $Connectorslist.Internal.properties.definitionSummary.triggers) {
                        $triggers = $Connectorslist.Internal.properties.definitionSummary.triggers
                        foreach ($trigger in $triggers.PSObject.Properties) {
                            $triggerValue = [string]$trigger.Value
                            if ($triggerValue -and $triggerValue -ne "manual" -and $triggerValue.Trim() -ne "") {
                                $AllConnectors += $triggerValue.Trim()
                            }
                        }
                    }

                    # Method 3: Extract from actions if still no connectors found
                    if ($AllConnectors.Count -eq 0 -and $Connectorslist.Internal.properties.definitionSummary.actions) {
                        $actions = $Connectorslist.Internal.properties.definitionSummary.actions
                        foreach ($action in $actions.PSObject.Properties) {
                            $actionValue = [string]$action.Value
                            if ($actionValue -and $actionValue -ne "manual" -and $actionValue.Trim() -ne "") {
                                $AllConnectors += $actionValue.Trim()
                            }
                        }
                    }

                } catch {
                    Write-Warning "Could not extract connector details for flow: $($FlowName.DisplayName). Using fallback method."
                    $AllConnectors = @("Unknown Connector")
                }

                # Clean up and deduplicate
                $UniqueConnectors = $AllConnectors | Select-Object -Unique | Where-Object { $_ -and $_ -ne "" -and $_ -notmatch "^@\{" }

                # Debug output
                Write-Host "DEBUG: Flow '$($FlowName.DisplayName)' found connectors: $($UniqueConnectors -join ', ')" -ForegroundColor Magenta

                # Create connector and tier strings
                $ConnectorString = if ($UniqueConnectors.Count -gt 0) { 
                    $UniqueConnectors -join "; " 
                } else { 
                    "None" 
                }

                $TierString = if ($UniqueConnectors.Count -gt 0) {
                    $TierArray = @()
                    foreach ($connector in $UniqueConnectors) {
                        $tier = Get-ConnectorTier $connector
                        Write-Host "DEBUG: Connector '$connector' assigned tier '$tier'" -ForegroundColor Yellow
                        $TierArray += $tier
                    }
                    $TierArray -join "; "
                } else {
                    "N/A"
                }

                # Create single record per flow with all connectors
                $ReportLine = [PSCustomObject]@{
                    Type                  = "PowerAutomate"
                    ItemId                = $FlowName.FlowName
                    ItemName              = $FlowName.DisplayName
                    Owner                 = $OwnerPrincipalName
                    EnvironmentId         = $Environment.EnvironmentName
                    EnvironmentName       = $Environment.DisplayName
                    Enabled               = $FlowName.Enabled
                    Connectors            = $ConnectorString
                    ConnectorTiers        = $TierString
                    LastModifiedTime      = $FlowName.LastModifiedTime
                    CreatedTime           = $FlowName.CreatedTime
                }

                $PowerAutomateReport.Add($ReportLine)

            } catch {
                Write-Warning "Failed to process flow: $($FlowName.DisplayName). Error: $($_.Exception.Message)"
            }
        }
    } catch {
        Write-Warning "Failed to process environment: $($Environment.DisplayName) for Power Automate. Error: $($_.Exception.Message)"
    }
}

Write-Host "Power Automate collection completed: $($PowerAutomateReport.Count) records" -ForegroundColor Green
Write-Host ""

########################### CREATE CONNECTOR SUMMARY #####################################
Write-Host "Creating connector summary by environment..." -ForegroundColor Green

# Combine all data for analysis
$AllData = $PowerAppsReport + $PowerAutomateReport
$SummaryReport = [System.Collections.Generic.List[Object]]::new()

# Group by environment first
$EnvironmentGroups = $AllData | Group-Object EnvironmentName

foreach ($EnvGroup in $EnvironmentGroups) {
    $EnvironmentName = $EnvGroup.Name
    $EnvironmentId = $EnvGroup.Group[0].EnvironmentId
    
    # Create a hashtable to track connector usage in this environment
    $ConnectorUsage = @{}
    
    foreach ($Item in $EnvGroup.Group) {
        if ($Item.Connectors -and $Item.Connectors -ne "None") {
            # Split connectors and tiers
            $Connectors = $Item.Connectors.Split(';').Trim()
            $Tiers = $Item.ConnectorTiers.Split(';').Trim()
            
            for ($i = 0; $i -lt $Connectors.Count; $i++) {
                $Connector = $Connectors[$i].Trim()
                $Tier = if ($i -lt $Tiers.Count) { $Tiers[$i].Trim() } else { "Standard" }
                
                if ($Connector -and $Connector -ne "") {
                    $Key = "$Connector|$Tier"
                    if ($ConnectorUsage.ContainsKey($Key)) {
                        $ConnectorUsage[$Key].UsageCount++
                        $ConnectorUsage[$Key].UsedByApps += $Item.ItemName
                        $ConnectorUsage[$Key].UsedByTypes += $Item.Type
                    } else {
                        $ConnectorUsage[$Key] = @{
                            ConnectorName = $Connector
                            Tier = $Tier
                            UsageCount = 1
                            UsedByApps = @($Item.ItemName)
                            UsedByTypes = @($Item.Type)
                        }
                    }
                }
            }
        }
    }
    
    # Create summary records for this environment
    foreach ($Usage in $ConnectorUsage.GetEnumerator()) {
        $UsageData = $Usage.Value
        $PowerAppCount = ($UsageData.UsedByTypes | Where-Object { $_ -eq "PowerApp" }).Count
        $FlowCount = ($UsageData.UsedByTypes | Where-Object { $_ -eq "PowerAutomate" }).Count
        
        $SummaryLine = [PSCustomObject]@{
            EnvironmentName = $EnvironmentName
            EnvironmentId = $EnvironmentId
            ConnectorName = $UsageData.ConnectorName
            ConnectorTier = $UsageData.Tier
            TotalUsageCount = $UsageData.UsageCount
            UsedByPowerApps = $PowerAppCount
            UsedByFlows = $FlowCount
            UsedByItems = $UsageData.UsedByApps -join "; "
        }
        
        $SummaryReport.Add($SummaryLine)
    }
}

Write-Host "Connector summary created: $($SummaryReport.Count) unique connector usages across all environments" -ForegroundColor Green
Write-Host ""

########################### EXPORT RESULTS #####################################
Write-Host "Exporting results..." -ForegroundColor Green

# Export individual reports
try {
    # Power Apps Export
    $PowerAppsReport | Sort-Object EnvironmentName, ItemName | Export-Csv -Path $PowerAppsCSVPath -Encoding UTF8 -NoTypeInformation
    Write-Host "Power Apps export completed: $($PowerAppsReport.Count) records" -ForegroundColor Green
    
    # Power Automate Export
    $PowerAutomateReport | Sort-Object EnvironmentName, ItemName | Export-Csv -Path $PowerAutomateCSVPath -Encoding UTF8 -NoTypeInformation
    Write-Host "Power Automate export completed: $($PowerAutomateReport.Count) records" -ForegroundColor Green
    
    # Combined Export
    $CombinedReport = $PowerAppsReport + $PowerAutomateReport
    $CombinedReport | Sort-Object Type, EnvironmentName, ItemName | Export-Csv -Path $CombinedCSVPath -Encoding UTF8 -NoTypeInformation
    Write-Host "Combined export completed: $($CombinedReport.Count) total records" -ForegroundColor Green
    
    # Summary Export
    $SummaryReport | Sort-Object EnvironmentName, ConnectorTier, ConnectorName | Export-Csv -Path $SummaryCSVPath -Encoding UTF8 -NoTypeInformation
    Write-Host "Summary export completed: $($SummaryReport.Count) connector usage records" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Export Summary:" -ForegroundColor Cyan
    Write-Host "   Power Apps: $($PowerAppsReport.Count) records" -ForegroundColor White
    Write-Host "   Power Automate: $($PowerAutomateReport.Count) records" -ForegroundColor White
    Write-Host "   Combined: $($CombinedReport.Count) records" -ForegroundColor White
    Write-Host "   Connector Summary: $($SummaryReport.Count) unique usages" -ForegroundColor White
    Write-Host ""
    
    # Open file location
    Start-Process "explorer.exe" "/select,`"$CombinedCSVPath`""
    
} catch {
    Write-Error "Failed to export data. Error: $($_.Exception.Message)"
}

Write-Host "Script completed! Total records exported: $($CombinedReport.Count)" -ForegroundColor Green
Write-Host "Files saved to: $ScriptPath" -ForegroundColor Yellow