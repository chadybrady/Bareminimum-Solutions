# Created by Tim Hjort 2025
# Enhanced Power Platform Governance Inventory
# Used to gather comprehensive inventory of Power Platform resources across tenant

# Required modules
$requiredModules = @(
    'Microsoft.PowerApps.Administration.PowerShell',
    'Microsoft.PowerApps.PowerShell',
    'ImportExcel'
)

# Function to install and import required modules
function Install-RequiredModules {
    param($modules)
    
    foreach ($module in $modules) {
        try {
            if (-not (Get-Module -Name $module -ListAvailable)) {
                Write-Host "Installing module: $module" -ForegroundColor Yellow
                Install-Module -Name $module -Force -Scope CurrentUser -ErrorAction Stop -AllowClobber
            } else {
                Write-Host "Module $module is already installed." -ForegroundColor Green
            }

            if (-not (Get-Module -Name $module)) {
                Import-Module $module -ErrorAction Stop
                Write-Host "Module $module has been imported." -ForegroundColor Green
            } else {
                Write-Host "Module $module is already imported." -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to install or import module $module : $_"
            return $false
        }
    }
    return $true
}

# Function to cleanup modules
function Remove-RequiredModules {
    param($modules)
    
    foreach ($module in $modules) {
        try {
            if (Get-Module -Name "$module*") {
                Write-Host "Removing module from current session: $module" -ForegroundColor Yellow
                Remove-Module -Name "$module*" -Force -ErrorAction Stop
            }

            $moduleVersions = Get-Module -Name "$module*" -ListAvailable
            foreach ($version in $moduleVersions) {
                Write-Host "Uninstalling module: $($version.Name) version $($version.Version)" -ForegroundColor Yellow
                Uninstall-Module -Name $version.Name -RequiredVersion $version.Version -Force -ErrorAction Stop
            }
            
            Write-Host "Module $module has been completely removed" -ForegroundColor Green
        } catch {
            Write-Error "Failed to remove/uninstall module $module : $_"
        }
    }
}

# Function to get all environments with detailed info
function Get-AllEnvironments {
    Write-Host "Retrieving environments..." -ForegroundColor Cyan
    
    $environments = Get-AdminPowerAppEnvironment
    $envDetails = @()
    
    foreach ($env in $environments) {
        try {
            $envInfo = [PSCustomObject]@{
                EnvironmentName = [string]$env.EnvironmentName
                DisplayName = [string]$env.DisplayName
                Location = [string]$env.Location
                EnvironmentType = [string]$env.EnvironmentType
                CreatedBy = if ($env.CreatedBy -and $env.CreatedBy.displayName) { [string]$env.CreatedBy.displayName } else { "Unknown" }
                CreatedTime = if ($env.CreatedTime) { [string]$env.CreatedTime } else { "" }
                LastModifiedTime = if ($env.LastModifiedTime) { [string]$env.LastModifiedTime } else { "" }
                State = [string]$env.Properties.provisioningState
                SecurityGroupId = if ($env.Properties.azureActiveDirectorySecurityGroupId) { [string]$env.Properties.azureActiveDirectorySecurityGroupId } else { "None" }
                IsDefault = [string]($env.IsDefault -eq $true)
                IsManaged = [string]($env.Properties.environmentSku -eq "Teams")
                DatabaseType = if ($env.Properties.databaseType) { [string]$env.Properties.databaseType } else { "None" }
                LinkedAppType = if ($env.Properties.linkedAppType) { [string]$env.Properties.linkedAppType } else { "None" }
                Templates = if ($env.Properties.templates) { [string]($env.Properties.templates -join ', ') } else { "None" }
                Version = if ($env.Properties.version) { [string]$env.Properties.version } else { "Unknown" }
            }
            $envDetails += $envInfo
        } catch {
            Write-Warning "Failed to get detailed info for environment $($env.DisplayName): $_"
        }
    }
    
    Write-Host "Found $($envDetails.Count) environments" -ForegroundColor Green
    return $envDetails
}

# Function to get all flows
function Get-AllFlows {
    param($environments)
    
    Write-Host "Retrieving flows from all environments..." -ForegroundColor Cyan
    $allFlows = @()
    
    foreach ($env in $environments) {
        Write-Host "Processing flows in environment: $($env.DisplayName)" -ForegroundColor Gray
        
        try {
            $flows = Get-AdminFlow -EnvironmentName $env.EnvironmentName
            
            if ($flows) {
                Write-Host "  Found $($flows.Count) flows" -ForegroundColor Green
                
                foreach ($flow in $flows) {
                    $createdBy = if ($flow.CreatedBy -and $flow.CreatedBy.displayName) {
                        $flow.CreatedBy.displayName
                    } elseif ($flow.CreatedBy -and $flow.CreatedBy.userPrincipalName) {
                        $flow.CreatedBy.userPrincipalName
                    } else {
                        "** ORPHANED FLOW - No Owner **"
                    }
                    
                    $flowInfo = [PSCustomObject]@{
                        EnvironmentName = [string]$env.EnvironmentName
                        EnvironmentDisplayName = [string]$env.DisplayName
                        FlowName = [string]$flow.FlowName
                        FlowDisplayName = [string]$flow.DisplayName
                        FlowId = [string]$flow.FlowId
                        CreatedBy = [string]$createdBy
                        CreatedTime = if ($flow.CreatedTime) { [string]$flow.CreatedTime } else { "" }
                        LastModifiedTime = if ($flow.LastModifiedTime) { [string]$flow.LastModifiedTime } else { "" }
                        State = [string]$flow.State
                        Enabled = [string]$flow.Enabled
                        TriggerType = if ($flow.Properties.definitionSummary.triggers.keys) { [string]($flow.Properties.definitionSummary.triggers.keys -join ', ') } else { "Unknown" }
                        IsOrphaned = [string]($createdBy -eq "** ORPHANED FLOW - No Owner **")
                        Shared = [string]($flow.Properties.sharingType -eq "Shared")
                        SharingType = if ($flow.Properties.sharingType) { [string]$flow.Properties.sharingType } else { "Unknown" }
                        ConnectionReferences = if ($flow.Properties.connectionReferences) { [string]($flow.Properties.connectionReferences.Keys -join ', ') } else { "None" }
                    }
                    $allFlows += $flowInfo
                }
            } else {
                Write-Host "  No flows found in this environment" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Failed to retrieve flows from environment $($env.DisplayName): $_"
        }
    }
    
    Write-Host "Total flows found: $($allFlows.Count)" -ForegroundColor Green
    return $allFlows
}

# Function to get all Power Apps
function Get-AllPowerApps {
    param($environments)
    
    Write-Host "Retrieving Power Apps from all environments..." -ForegroundColor Cyan
    $allApps = @()
    
    foreach ($env in $environments) {
        Write-Host "Processing apps in environment: $($env.DisplayName)" -ForegroundColor Gray
        
        try {
            $apps = Get-AdminPowerApp -EnvironmentName $env.EnvironmentName
            
            if ($apps) {
                Write-Host "  Found $($apps.Count) apps" -ForegroundColor Green
                
                foreach ($app in $apps) {
                    $createdBy = if ($app.CreatedBy -and $app.CreatedBy.displayName) {
                        $app.CreatedBy.displayName
                    } elseif ($app.CreatedBy -and $app.CreatedBy.userPrincipalName) {
                        $app.CreatedBy.userPrincipalName
                    } else {
                        "** ORPHANED APP - No Owner **"
                    }
                    
                    $appInfo = [PSCustomObject]@{
                        EnvironmentName = [string]$env.EnvironmentName
                        EnvironmentDisplayName = [string]$env.DisplayName
                        AppName = [string]$app.AppName
                        AppDisplayName = [string]$app.DisplayName
                        AppId = [string]$app.AppId
                        CreatedBy = [string]$createdBy
                        CreatedTime = if ($app.CreatedTime) { [string]$app.CreatedTime } else { "" }
                        LastModifiedTime = if ($app.LastModifiedTime) { [string]$app.LastModifiedTime } else { "" }
                        LastLaunchTime = if ($app.LastLaunchTime) { [string]$app.LastLaunchTime } else { "Never" }
                        Published = [string]($app.Published -eq $true)
                        IsOrphaned = [string]($createdBy -eq "** ORPHANED APP - No Owner **")
                        Shared = [string]($app.Properties.sharingType -eq "Shared")
                        SharingType = if ($app.Properties.sharingType) { [string]$app.Properties.sharingType } else { "Unknown" }
                        AppType = if ($app.Properties.appType) { [string]$app.Properties.appType } else { "Canvas" }
                        AppVersion = if ($app.Properties.appVersion) { [string]$app.Properties.appVersion } else { "Unknown" }
                        ConnectionReferences = if ($app.Properties.connectionReferences) { [string]($app.Properties.connectionReferences.Keys -join ', ') } else { "None" }
                        UnpublishedAppVersion = if ($app.Properties.unpublishedAppVersion) { [string]$app.Properties.unpublishedAppVersion } else { "None" }
                        IsFeaturedApp = [string]($app.Properties.isFeaturedApp -eq $true)
                        IsHeroApp = [string]($app.Properties.isHeroApp -eq $true)
                    }
                    $allApps += $appInfo
                }
            } else {
                Write-Host "  No apps found in this environment" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Failed to retrieve apps from environment $($env.DisplayName): $_"
        }
    }
    
    Write-Host "Total apps found: $($allApps.Count)" -ForegroundColor Green
    return $allApps
}

# Function to get all DLP policies
function Get-AllDLPPolicies {
    Write-Host "Retrieving DLP policies..." -ForegroundColor Cyan
    
    $allPolicies = @()
    
    try {
        $policies = Get-AdminDlpPolicy
        
        if ($policies) {
            Write-Host "Found $($policies.Count) DLP policies" -ForegroundColor Green
            
            foreach ($policy in $policies) {
                $policyInfo = [PSCustomObject]@{
                    PolicyName = [string]$policy.PolicyName
                    DisplayName = [string]$policy.DisplayName
                    CreatedBy = if ($policy.CreatedBy -and $policy.CreatedBy.displayName) { [string]$policy.CreatedBy.displayName } else { "Unknown" }
                    CreatedTime = if ($policy.CreatedTime) { [string]$policy.CreatedTime } else { "" }
                    LastModifiedTime = if ($policy.LastModifiedTime) { [string]$policy.LastModifiedTime } else { "" }
                    State = [string]$policy.State
                    Type = [string]$policy.Type
                    DefaultConnectorsClassification = [string]$policy.DefaultConnectorsClassification
                    EnvironmentCount = if ($policy.Environments) { [string]$policy.Environments.Count } else { "0" }
                    Environments = if ($policy.Environments) { [string]($policy.Environments.name -join ', ') } else { "None" }
                    BusinessDataGroupCount = if ($policy.ConnectorGroups -and $policy.ConnectorGroups[0]) { [string]$policy.ConnectorGroups[0].connectors.Count } else { "0" }
                    NonBusinessDataGroupCount = if ($policy.ConnectorGroups -and $policy.ConnectorGroups[1]) { [string]$policy.ConnectorGroups[1].connectors.Count } else { "0" }
                    BlockedDataGroupCount = if ($policy.ConnectorGroups -and $policy.ConnectorGroups[2]) { [string]$policy.ConnectorGroups[2].connectors.Count } else { "0" }
                    HttpUrlPatternsCount = if ($policy.ConnectorGroups -and $policy.ConnectorGroups[0] -and $policy.ConnectorGroups[0].connectors) { 
                        $httpConnectors = $policy.ConnectorGroups[0].connectors | Where-Object { $_.id -eq "/providers/Microsoft.PowerApps/apis/shared_webcontents" }
                        if ($httpConnectors -and $httpConnectors.apiPolicies) { [string]$httpConnectors.apiPolicies.Count } else { "0" }
                    } else { "0" }
                    CustomConnectorPatternsCount = if ($policy.CustomConnectorUrlPatterns) { [string]$policy.CustomConnectorUrlPatterns.Count } else { "0" }
                }
                $allPolicies += $policyInfo
            }
        } else {
            Write-Host "No DLP policies found" -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "Failed to retrieve DLP policies: $_"
    }
    
    return $allPolicies
}

# Function to get all connections
function Get-AllConnections {
    param($environments)
    
    Write-Host "Retrieving connections from all environments..." -ForegroundColor Cyan
    $allConnections = @()
    
    foreach ($env in $environments) {
        Write-Host "Processing connections in environment: $($env.DisplayName)" -ForegroundColor Gray
        
        try {
            $connections = Get-AdminPowerAppConnection -EnvironmentName $env.EnvironmentName
            
            if ($connections) {
                Write-Host "  Found $($connections.Count) connections" -ForegroundColor Green
                
                foreach ($connection in $connections) {
                    $createdBy = if ($connection.CreatedBy -and $connection.CreatedBy.displayName) {
                        $connection.CreatedBy.displayName
                    } elseif ($connection.CreatedBy -and $connection.CreatedBy.userPrincipalName) {
                        $connection.CreatedBy.userPrincipalName
                    } else {
                        "** ORPHANED CONNECTION - No Owner **"
                    }
                    
                    $connectionInfo = [PSCustomObject]@{
                        EnvironmentName = [string]$env.EnvironmentName
                        EnvironmentDisplayName = [string]$env.DisplayName
                        ConnectionName = [string]$connection.ConnectionName
                        ConnectionId = [string]$connection.ConnectionId
                        ConnectorName = [string]$connection.ConnectorName
                        DisplayName = [string]$connection.DisplayName
                        CreatedBy = [string]$createdBy
                        CreatedTime = if ($connection.CreatedTime) { [string]$connection.CreatedTime } else { "" }
                        LastModifiedTime = if ($connection.LastModifiedTime) { [string]$connection.LastModifiedTime } else { "" }
                        ConnectionStatus = [string]$connection.Status
                        IsOrphaned = [string]($createdBy -eq "** ORPHANED CONNECTION - No Owner **")
                        IsShared = [string]($connection.Properties.sharingType -eq "Shared")
                        ApiTier = if ($connection.Properties.apiTier) { [string]$connection.Properties.apiTier } else { "Unknown" }
                        IsCustomApi = [string]($connection.Properties.isCustomApi -eq $true)
                        TestLinks = if ($connection.Properties.testLinks) { [string]($connection.Properties.testLinks.Count) } else { "0" }
                    }
                    $allConnections += $connectionInfo
                }
            } else {
                Write-Host "  No connections found in this environment" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Failed to retrieve connections from environment $($env.DisplayName): $_"
        }
    }
    
    Write-Host "Total connections found: $($allConnections.Count)" -ForegroundColor Green
    return $allConnections
}

# Function to get all custom connectors
function Get-AllCustomConnectors {
    param($environments)
    
    Write-Host "Retrieving custom connectors from all environments..." -ForegroundColor Cyan
    $allCustomConnectors = @()
    
    foreach ($env in $environments) {
        Write-Host "Processing custom connectors in environment: $($env.DisplayName)" -ForegroundColor Gray
        
        try {
            $connectors = Get-AdminPowerAppConnector -EnvironmentName $env.EnvironmentName
            
            if ($connectors) {
                Write-Host "  Found $($connectors.Count) custom connectors" -ForegroundColor Green
                
                foreach ($connector in $connectors) {
                    $createdBy = if ($connector.CreatedBy -and $connector.CreatedBy.displayName) {
                        $connector.CreatedBy.displayName
                    } elseif ($connector.CreatedBy -and $connector.CreatedBy.userPrincipalName) {
                        $connector.CreatedBy.userPrincipalName
                    } else {
                        "** ORPHANED CONNECTOR - No Owner **"
                    }
                    
                    $connectorInfo = [PSCustomObject]@{
                        EnvironmentName = [string]$env.EnvironmentName
                        EnvironmentDisplayName = [string]$env.DisplayName
                        ConnectorName = [string]$connector.ConnectorName
                        ConnectorId = [string]$connector.ConnectorId
                        DisplayName = [string]$connector.DisplayName
                        CreatedBy = [string]$createdBy
                        CreatedTime = if ($connector.CreatedTime) { [string]$connector.CreatedTime } else { "" }
                        LastModifiedTime = if ($connector.LastModifiedTime) { [string]$connector.LastModifiedTime } else { "" }
                        IsOrphaned = [string]($createdBy -eq "** ORPHANED CONNECTOR - No Owner **")
                        ApiVersion = if ($connector.Properties.apiVersion) { [string]$connector.Properties.apiVersion } else { "Unknown" }
                        Tier = if ($connector.Properties.tier) { [string]$connector.Properties.tier } else { "Unknown" }
                        IsCustomApi = [string]($connector.Properties.isCustomApi -eq $true)
                        Publisher = if ($connector.Properties.publisher) { [string]$connector.Properties.publisher } else { "Unknown" }
                        Description = if ($connector.Properties.description) { [string]$connector.Properties.description } else { "None" }
                        IconUri = if ($connector.Properties.iconUri) { [string]$connector.Properties.iconUri } else { "None" }
                    }
                    $allCustomConnectors += $connectorInfo
                }
            } else {
                Write-Host "  No custom connectors found in this environment" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Failed to retrieve custom connectors from environment $($env.DisplayName): $_"
        }
    }
    
    Write-Host "Total custom connectors found: $($allCustomConnectors.Count)" -ForegroundColor Green
    return $allCustomConnectors
}

# Function to create summary data
function Create-SummaryData {
    param($environments, $flows, $apps, $policies, $connections, $customConnectors)
    
    Write-Host "Creating summary data..." -ForegroundColor Cyan
    
    # Overall Summary
    $overallSummary = @()
    $overallSummary += [PSCustomObject]@{ Metric = "Total Environments"; Value = $environments.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Production Environments"; Value = ($environments | Where-Object {$_.EnvironmentType -eq "Production"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Sandbox Environments"; Value = ($environments | Where-Object {$_.EnvironmentType -eq "Sandbox"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Default Environments"; Value = ($environments | Where-Object {$_.IsDefault -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Teams Environments"; Value = ($environments | Where-Object {$_.IsManaged -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = ""; Value = "" }
    $overallSummary += [PSCustomObject]@{ Metric = "Total Flows"; Value = $flows.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Enabled Flows"; Value = ($flows | Where-Object {$_.Enabled -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Running Flows"; Value = ($flows | Where-Object {$_.State -eq "Started"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Orphaned Flows"; Value = ($flows | Where-Object {$_.IsOrphaned -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = ""; Value = "" }
    $overallSummary += [PSCustomObject]@{ Metric = "Total Apps"; Value = $apps.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Published Apps"; Value = ($apps | Where-Object {$_.Published -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Orphaned Apps"; Value = ($apps | Where-Object {$_.IsOrphaned -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Featured Apps"; Value = ($apps | Where-Object {$_.IsFeaturedApp -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = ""; Value = "" }
    $overallSummary += [PSCustomObject]@{ Metric = "Total Connections"; Value = $connections.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Orphaned Connections"; Value = ($connections | Where-Object {$_.IsOrphaned -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Custom Connectors"; Value = $customConnectors.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Orphaned Custom Connectors"; Value = ($customConnectors | Where-Object {$_.IsOrphaned -eq "True"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = ""; Value = "" }
    $overallSummary += [PSCustomObject]@{ Metric = "DLP Policies"; Value = $policies.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Active DLP Policies"; Value = ($policies | Where-Object {$_.State -eq "Enabled"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = ""; Value = "" }
    $overallSummary += [PSCustomObject]@{ Metric = "Report Generated"; Value = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }
    
    # Environment Summary
    $envSummary = $environments | ForEach-Object {
        $env = $_
        $envFlows = $flows | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}
        $envApps = $apps | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}
        $envConnections = $connections | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}
        $envCustomConnectors = $customConnectors | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}
        
        [PSCustomObject]@{
            EnvironmentName = [string]$env.DisplayName
            EnvironmentType = [string]$env.EnvironmentType
            Location = [string]$env.Location
            IsDefault = [string]$env.IsDefault
            IsManaged = [string]$env.IsManaged
            TotalFlows = [string]$envFlows.Count
            EnabledFlows = [string]($envFlows | Where-Object {$_.Enabled -eq "True"}).Count
            OrphanedFlows = [string]($envFlows | Where-Object {$_.IsOrphaned -eq "True"}).Count
            TotalApps = [string]$envApps.Count
            PublishedApps = [string]($envApps | Where-Object {$_.Published -eq "True"}).Count
            OrphanedApps = [string]($envApps | Where-Object {$_.IsOrphaned -eq "True"}).Count
            TotalConnections = [string]$envConnections.Count
            OrphanedConnections = [string]($envConnections | Where-Object {$_.IsOrphaned -eq "True"}).Count
            CustomConnectors = [string]$envCustomConnectors.Count
            OrphanedCustomConnectors = [string]($envCustomConnectors | Where-Object {$_.IsOrphaned -eq "True"}).Count
            CreatedBy = [string]$env.CreatedBy
            CreatedTime = [string]$env.CreatedTime
        }
    }
    
    # Creator Summary
    $allCreators = @()
    $allCreators += $flows | Where-Object {$_.IsOrphaned -eq "False"} | Select-Object CreatedBy, @{Name='Type'; Expression={'Flow'}}
    $allCreators += $apps | Where-Object {$_.IsOrphaned -eq "False"} | Select-Object CreatedBy, @{Name='Type'; Expression={'App'}}
    $allCreators += $connections | Where-Object {$_.IsOrphaned -eq "False"} | Select-Object CreatedBy, @{Name='Type'; Expression={'Connection'}}
    $allCreators += $customConnectors | Where-Object {$_.IsOrphaned -eq "False"} | Select-Object CreatedBy, @{Name='Type'; Expression={'Custom Connector'}}
    
    $creatorSummary = $allCreators | Group-Object CreatedBy | ForEach-Object {
        $creatorItems = $_.Group
        $creatorFlows = $flows | Where-Object {$_.CreatedBy -eq $_.Name -and $_.IsOrphaned -eq "False"}
        $creatorApps = $apps | Where-Object {$_.CreatedBy -eq $_.Name -and $_.IsOrphaned -eq "False"}
        $creatorConnections = $connections | Where-Object {$_.CreatedBy -eq $_.Name -and $_.IsOrphaned -eq "False"}
        $creatorCustomConnectors = $customConnectors | Where-Object {$_.CreatedBy -eq $_.Name -and $_.IsOrphaned -eq "False"}
        
        [PSCustomObject]@{
            CreatedBy = [string]$_.Name
            TotalItems = [string]$creatorItems.Count
            Flows = [string]$creatorFlows.Count
            Apps = [string]$creatorApps.Count
            Connections = [string]$creatorConnections.Count
            CustomConnectors = [string]$creatorCustomConnectors.Count
            EnabledFlows = [string]($creatorFlows | Where-Object {$_.Enabled -eq "True"}).Count
            PublishedApps = [string]($creatorApps | Where-Object {$_.Published -eq "True"}).Count
            UniqueEnvironments = [string]($creatorItems | Select-Object -ExpandProperty EnvironmentName -ErrorAction SilentlyContinue | Select-Object -Unique).Count
        }
    } | Sort-Object { [int]$_.TotalItems } -Descending
    
    # Orphaned Resources Summary
    $orphanedSummary = $environments | ForEach-Object {
        $env = $_
        $orphanedFlows = $flows | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName -and $_.IsOrphaned -eq "True"}
        $orphanedApps = $apps | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName -and $_.IsOrphaned -eq "True"}
        $orphanedConnections = $connections | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName -and $_.IsOrphaned -eq "True"}
        $orphanedCustomConnectors = $customConnectors | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName -and $_.IsOrphaned -eq "True"}
        
        if ($orphanedFlows.Count -gt 0 -or $orphanedApps.Count -gt 0 -or $orphanedConnections.Count -gt 0 -or $orphanedCustomConnectors.Count -gt 0) {
            [PSCustomObject]@{
                EnvironmentName = [string]$env.DisplayName
                OrphanedFlows = [string]$orphanedFlows.Count
                OrphanedApps = [string]$orphanedApps.Count
                OrphanedConnections = [string]$orphanedConnections.Count
                OrphanedCustomConnectors = [string]$orphanedCustomConnectors.Count
                TotalOrphaned = [string]($orphanedFlows.Count + $orphanedApps.Count + $orphanedConnections.Count + $orphanedCustomConnectors.Count)
                EnabledOrphanedFlows = [string]($orphanedFlows | Where-Object {$_.Enabled -eq "True"}).Count
                PublishedOrphanedApps = [string]($orphanedApps | Where-Object {$_.Published -eq "True"}).Count
            }
        }
    } | Where-Object { $_ -ne $null }
    
    if ($orphanedSummary.Count -eq 0) {
        $orphanedSummary = @([PSCustomObject]@{
            EnvironmentName = "No orphaned resources found"
            OrphanedFlows = "0"
            OrphanedApps = "0"
            OrphanedConnections = "0"
            OrphanedCustomConnectors = "0"
            TotalOrphaned = "0"
            EnabledOrphanedFlows = "0"
            PublishedOrphanedApps = "0"
        })
    }
    
    # DLP Policy Summary
    $dlpSummary = if ($policies.Count -gt 0) {
        $policies | ForEach-Object {
            [PSCustomObject]@{
                PolicyName = [string]$_.DisplayName
                State = [string]$_.State
                Type = [string]$_.Type
                EnvironmentCount = [string]$_.EnvironmentCount
                BusinessConnectors = [string]$_.BusinessDataGroupCount
                NonBusinessConnectors = [string]$_.NonBusinessDataGroupCount
                BlockedConnectors = [string]$_.BlockedDataGroupCount
                HttpPatterns = [string]$_.HttpUrlPatternsCount
                CustomPatterns = [string]$_.CustomConnectorPatternsCount
                CreatedBy = [string]$_.CreatedBy
                CreatedTime = [string]$_.CreatedTime
                LastModifiedTime = [string]$_.LastModifiedTime
            }
        }
    } else {
        @([PSCustomObject]@{
            PolicyName = "No DLP policies found"
            State = "N/A"
            Type = "N/A"
            EnvironmentCount = "0"
            BusinessConnectors = "0"
            NonBusinessConnectors = "0"
            BlockedConnectors = "0"
            HttpPatterns = "0"
            CustomPatterns = "0"
            CreatedBy = "N/A"
            CreatedTime = ""
            LastModifiedTime = ""
        })
    }
    
    # Connection Summary by Connector Type
    $connectionSummary = $connections | Group-Object ConnectorName | ForEach-Object {
        $connectorConnections = $_.Group
        [PSCustomObject]@{
            ConnectorName = [string]$_.Name
            TotalConnections = [string]$_.Count
            UniqueCreators = [string]($connectorConnections | Where-Object {$_.IsOrphaned -eq "False"} | Select-Object CreatedBy -Unique).Count
            OrphanedConnections = [string]($connectorConnections | Where-Object {$_.IsOrphaned -eq "True"}).Count
            SharedConnections = [string]($connectorConnections | Where-Object {$_.IsShared -eq "True"}).Count
            UniqueEnvironments = [string]($connectorConnections | Select-Object EnvironmentName -Unique).Count
            CustomConnector = [string]($connectorConnections | Where-Object {$_.IsCustomApi -eq "True"}).Count
        }
    } | Sort-Object { [int]$_.TotalConnections } -Descending
    
    return @{
        Overall = $overallSummary
        Environment = $envSummary
        Creator = $creatorSummary
        Orphaned = $orphanedSummary
        DLP = $dlpSummary
        Connection = $connectionSummary
    }
}

# Function to display governance insights
function Show-GovernanceInsights {
    param($environments, $flows, $apps, $policies, $connections, $customConnectors)
    
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "POWER PLATFORM GOVERNANCE INSIGHTS" -ForegroundColor Cyan
    Write-Host "="*80 -ForegroundColor Cyan
    
    # Environment insights
    Write-Host "`nEnvironment Summary:" -ForegroundColor Yellow
    Write-Host "- Total Environments: $($environments.Count)" -ForegroundColor White
    Write-Host "- Production: $(($environments | Where-Object {$_.EnvironmentType -eq 'Production'}).Count)" -ForegroundColor Green
    Write-Host "- Sandbox: $(($environments | Where-Object {$_.EnvironmentType -eq 'Sandbox'}).Count)" -ForegroundColor Yellow
    Write-Host "- Default: $(($environments | Where-Object {$_.IsDefault -eq 'True'}).Count)" -ForegroundColor Cyan
    Write-Host "- Teams-managed: $(($environments | Where-Object {$_.IsManaged -eq 'True'}).Count)" -ForegroundColor Blue
    
    # Flow insights
    Write-Host "`nFlow Summary:" -ForegroundColor Yellow
    Write-Host "- Total Flows: $($flows.Count)" -ForegroundColor White
    Write-Host "- Enabled: $(($flows | Where-Object {$_.Enabled -eq 'True'}).Count)" -ForegroundColor Green
    Write-Host "- Running: $(($flows | Where-Object {$_.State -eq 'Started'}).Count)" -ForegroundColor Green
    Write-Host "- Shared: $(($flows | Where-Object {$_.Shared -eq 'True'}).Count)" -ForegroundColor Cyan
    Write-Host "- Orphaned: $(($flows | Where-Object {$_.IsOrphaned -eq 'True'}).Count)" -ForegroundColor Red
    
    # App insights
    Write-Host "`nApp Summary:" -ForegroundColor Yellow
    Write-Host "- Total Apps: $($apps.Count)" -ForegroundColor White
    Write-Host "- Published: $(($apps | Where-Object {$_.Published -eq 'True'}).Count)" -ForegroundColor Green
    Write-Host "- Shared: $(($apps | Where-Object {$_.Shared -eq 'True'}).Count)" -ForegroundColor Cyan
    Write-Host "- Featured: $(($apps | Where-Object {$_.IsFeaturedApp -eq 'True'}).Count)" -ForegroundColor Yellow
    Write-Host "- Orphaned: $(($apps | Where-Object {$_.IsOrphaned -eq 'True'}).Count)" -ForegroundColor Red
    
    # Connection insights
    Write-Host "`nConnection Summary:" -ForegroundColor Yellow
    Write-Host "- Total Connections: $($connections.Count)" -ForegroundColor White
    Write-Host "- Shared: $(($connections | Where-Object {$_.IsShared -eq 'True'}).Count)" -ForegroundColor Cyan
    Write-Host "- Custom Connectors: $($customConnectors.Count)" -ForegroundColor Yellow
    Write-Host "- Orphaned: $(($connections | Where-Object {$_.IsOrphaned -eq 'True'}).Count + ($customConnectors | Where-Object {$_.IsOrphaned -eq 'True'}).Count)" -ForegroundColor Red
    
    # DLP insights
    Write-Host "`nDLP Policy Summary:" -ForegroundColor Yellow
    Write-Host "- Total Policies: $($policies.Count)" -ForegroundColor White
    Write-Host "- Active: $(($policies | Where-Object {$_.State -eq 'Enabled'}).Count)" -ForegroundColor Green
    Write-Host "- Tenant-wide: $(($policies | Where-Object {$_.Type -eq 'Tenant'}).Count)" -ForegroundColor Cyan
    
    # Governance warnings
    $totalOrphaned = ($flows | Where-Object {$_.IsOrphaned -eq 'True'}).Count + 
                     ($apps | Where-Object {$_.IsOrphaned -eq 'True'}).Count + 
                     ($connections | Where-Object {$_.IsOrphaned -eq 'True'}).Count + 
                     ($customConnectors | Where-Object {$_.IsOrphaned -eq 'True'}).Count
    
    if ($totalOrphaned -gt 0) {
        Write-Host "`nGOVERNANCE ALERTS:" -ForegroundColor Red
        Write-Host "   Found $totalOrphaned orphaned resources across all environments!" -ForegroundColor Yellow
        Write-Host "   These resources may need administrative attention or cleanup." -ForegroundColor Yellow
    }
    
    if ($policies.Count -eq 0) {
        Write-Host "`nGOVERNANCE ALERT:" -ForegroundColor Red
        Write-Host "   No DLP policies found! Consider implementing data loss prevention." -ForegroundColor Yellow
    }
    
    # Environment distribution
    Write-Host "`nTop 5 Environments by Resource Count:" -ForegroundColor Yellow
    $envResourceCount = $environments | ForEach-Object {
        $env = $_
        $resourceCount = ($flows | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}).Count +
                        ($apps | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}).Count +
                        ($connections | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}).Count +
                        ($customConnectors | Where-Object {$_.EnvironmentName -eq $env.EnvironmentName}).Count
        
        [PSCustomObject]@{
            Environment = $env.DisplayName
            Resources = $resourceCount
            Type = $env.EnvironmentType
        }
    } | Sort-Object Resources -Descending | Select-Object -First 5
    
    foreach ($env in $envResourceCount) {
        Write-Host "   $($env.Environment): $($env.Resources) resources ($($env.Type))" -ForegroundColor White
    }
    
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
}

# Main script execution
try {
    Write-Host "Starting Power Platform Governance Inventory..." -ForegroundColor Cyan
    Write-Host "This comprehensive scan will inventory all Power Platform resources" -ForegroundColor Gray
    
    # Install and import required modules
    if (-not (Install-RequiredModules -modules $requiredModules)) {
        throw "Failed to install required modules"
    }

    # Authenticate to Power Platform
    Write-Host "Authenticating to Power Platform..." -ForegroundColor Cyan
    Add-PowerAppsAccount

    # Get all environments first
    $environments = Get-AllEnvironments
    
    if ($environments.Count -eq 0) {
        Write-Warning "No environments found! This could indicate:"
        Write-Host "  1. Authentication issues" -ForegroundColor Yellow
        Write-Host "  2. Insufficient permissions" -ForegroundColor Yellow
        Write-Host "  3. No Power Platform environments in tenant" -ForegroundColor Yellow
        return
    }

    # Get all resources
    Write-Host "`nGathering all Power Platform resources..." -ForegroundColor Cyan
    $flows = Get-AllFlows -environments $environments
    $apps = Get-AllPowerApps -environments $environments
    $policies = Get-AllDLPPolicies
    $connections = Get-AllConnections -environments $environments
    $customConnectors = Get-AllCustomConnectors -environments $environments

    # Create summary data
    $summaries = Create-SummaryData -environments $environments -flows $flows -apps $apps -policies $policies -connections $connections -customConnectors $customConnectors

    # Display insights
    Show-GovernanceInsights -environments $environments -flows $flows -apps $apps -policies $policies -connections $connections -customConnectors $customConnectors

    # Export to Excel with multiple sheets
    $exportPath = "PowerPlatformGovernanceInventory_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
    
    Write-Host "`nExporting comprehensive report to Excel..." -ForegroundColor Cyan
    
    try {
        # Export all data to separate worksheets
        $summaries.Overall | Export-Excel -Path $exportPath -WorksheetName "Overall Summary" -AutoSize -FreezeTopRow
        $summaries.Environment | Export-Excel -Path $exportPath -WorksheetName "Environment Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        $summaries.Creator | Export-Excel -Path $exportPath -WorksheetName "Creator Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        $summaries.Orphaned | Export-Excel -Path $exportPath -WorksheetName "Orphaned Resources" -AutoSize -AutoFilter -FreezeTopRow -Append
        $summaries.DLP | Export-Excel -Path $exportPath -WorksheetName "DLP Policies" -AutoSize -AutoFilter -FreezeTopRow -Append
        $summaries.Connection | Export-Excel -Path $exportPath -WorksheetName "Connection Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        
        # Export detailed inventories
        $environments | Export-Excel -Path $exportPath -WorksheetName "All Environments" -AutoSize -AutoFilter -FreezeTopRow -Append
        $flows | Export-Excel -Path $exportPath -WorksheetName "All Flows" -AutoSize -AutoFilter -FreezeTopRow -Append
        $apps | Export-Excel -Path $exportPath -WorksheetName "All Apps" -AutoSize -AutoFilter -FreezeTopRow -Append
        $connections | Export-Excel -Path $exportPath -WorksheetName "All Connections" -AutoSize -AutoFilter -FreezeTopRow -Append
        $customConnectors | Export-Excel -Path $exportPath -WorksheetName "Custom Connectors" -AutoSize -AutoFilter -FreezeTopRow -Append
        $policies | Export-Excel -Path $exportPath -WorksheetName "All DLP Policies" -AutoSize -AutoFilter -FreezeTopRow -Append
        
        Write-Host "Comprehensive governance report exported successfully!" -ForegroundColor Green
        Write-Host "File location: $exportPath" -ForegroundColor Cyan
        
        Write-Host "`nExcel worksheets created:" -ForegroundColor Yellow
        Write-Host "Summary Sheets:" -ForegroundColor Cyan
        Write-Host "  - Overall Summary: High-level tenant statistics" -ForegroundColor White
        Write-Host "  - Environment Summary: Resource counts by environment" -ForegroundColor White
        Write-Host "  - Creator Summary: Resource ownership analysis" -ForegroundColor White
        Write-Host "  - Orphaned Resources: Resources without owners" -ForegroundColor White
        Write-Host "  - DLP Policies: Data loss prevention overview" -ForegroundColor White
        Write-Host "  - Connection Summary: Connector usage statistics" -ForegroundColor White
        
        Write-Host "Detailed Inventories:" -ForegroundColor Cyan
        Write-Host "  - All Environments: Complete environment details" -ForegroundColor White
        Write-Host "  - All Flows: Complete flow inventory" -ForegroundColor White
        Write-Host "  - All Apps: Complete app inventory" -ForegroundColor White
        Write-Host "  - All Connections: Complete connection inventory" -ForegroundColor White
        Write-Host "  - Custom Connectors: Custom connector details" -ForegroundColor White
        Write-Host "  - All DLP Policies: Detailed policy configurations" -ForegroundColor White
        
    } catch {
        Write-Warning "Failed to create Excel file. Falling back to CSV export: $_"
        
        # Fallback to CSV files
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $environments | Export-Csv -Path "PP_Environments_$timestamp.csv" -NoTypeInformation -Encoding UTF8
        $flows | Export-Csv -Path "PP_Flows_$timestamp.csv" -NoTypeInformation -Encoding UTF8
        $apps | Export-Csv -Path "PP_Apps_$timestamp.csv" -NoTypeInformation -Encoding UTF8
        $connections | Export-Csv -Path "PP_Connections_$timestamp.csv" -NoTypeInformation -Encoding UTF8
        $customConnectors | Export-Csv -Path "PP_CustomConnectors_$timestamp.csv" -NoTypeInformation -Encoding UTF8
        $policies | Export-Csv -Path "PP_DLPPolicies_$timestamp.csv" -NoTypeInformation -Encoding UTF8
        
        Write-Host "Data exported to separate CSV files with timestamp: $timestamp" -ForegroundColor Yellow
    }

    # Display sample data for verification
    Write-Host "`nSample data verification:" -ForegroundColor Cyan
    if ($environments.Count -gt 0) {
        Write-Host "[OK] Environments: $($environments.Count) found" -ForegroundColor Green
    }
    if ($flows.Count -gt 0) {
        Write-Host "[OK] Flows: $($flows.Count) found" -ForegroundColor Green
    }
    if ($apps.Count -gt 0) {
        Write-Host "[OK] Apps: $($apps.Count) found" -ForegroundColor Green
    }
    if ($connections.Count -gt 0) {
        Write-Host "[OK] Connections: $($connections.Count) found" -ForegroundColor Green
    }
    if ($customConnectors.Count -gt 0) {
        Write-Host "[OK] Custom Connectors: $($customConnectors.Count) found" -ForegroundColor Green
    }
    if ($policies.Count -gt 0) {
        Write-Host "[OK] DLP Policies: $($policies.Count) found" -ForegroundColor Green
    }

    Write-Host "`nPower Platform Governance Inventory completed successfully!" -ForegroundColor Green
    Write-Host "Use the generated report for governance, compliance, and optimization insights." -ForegroundColor Cyan

} catch {
    Write-Error "Script execution failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
} finally {
    # Cleanup modules - ALWAYS runs even if script fails
    Write-Host "`nCleaning up modules..." -ForegroundColor Cyan
    # Comment out the cleanup if you want to keep modules for subsequent runs
    # Remove-RequiredModules -modules $requiredModules
    Write-Host "Module cleanup completed (modules kept for subsequent runs)." -ForegroundColor Green
}