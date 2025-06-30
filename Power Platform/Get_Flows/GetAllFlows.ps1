# Created by Tim Hjort 2025
# Used to gather all flows in a tenant from each environment

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

            # Import the module if not already imported
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
            # Remove from current session
            if (Get-Module -Name "$module*") {
                Write-Host "Removing module from current session: $module" -ForegroundColor Yellow
                Remove-Module -Name "$module*" -Force -ErrorAction Stop
            }

            # Uninstall all versions
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

# Main script execution
try {
    Write-Host "Starting Power Platform Flow Inventory..." -ForegroundColor Cyan
    
    # Install and import required modules
    if (-not (Install-RequiredModules -modules $requiredModules)) {
        throw "Failed to install required modules"
    }

    # Authenticate to Power Platform
    Write-Host "Authenticating to Power Platform..." -ForegroundColor Cyan
    Add-PowerAppsAccount

    # Get all environments
    Write-Host "Retrieving environments..." -ForegroundColor Cyan
    $environments = Get-AdminPowerAppEnvironment
    Write-Host "Found $($environments.Count) environments" -ForegroundColor Green

    # Initialize results array
    $allFlows = @()

    # Process each environment
    foreach ($env in $environments) {
        Write-Host "Processing environment: $($env.DisplayName) ($($env.EnvironmentName))" -ForegroundColor Cyan
        
        try {
            # Get flows for this environment
            $flows = Get-AdminFlow -EnvironmentName $env.EnvironmentName
            
            if ($flows) {
                Write-Host "  Found $($flows.Count) flows" -ForegroundColor Green
                
                # Add environment info to each flow
                foreach ($flow in $flows) {
                    $flowInfo = [PSCustomObject]@{
                        EnvironmentName = $env.EnvironmentName
                        EnvironmentDisplayName = $env.DisplayName
                        FlowName = $flow.FlowName
                        FlowDisplayName = $flow.DisplayName
                        FlowId = $flow.FlowId
                        CreatedBy = $flow.CreatedBy.displayName
                        CreatedTime = $flow.CreatedTime
                        LastModifiedTime = $flow.LastModifiedTime
                        State = $flow.State
                        Enabled = $flow.Enabled
                        TriggerType = $flow.Properties.definitionSummary.triggers.keys -join ', '
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

    # Display summary statistics
    Write-Host "`nFlow Inventory Summary:" -ForegroundColor Cyan
    Write-Host "Total Environments: $($environments.Count)" -ForegroundColor Green
    Write-Host "Total Flows Found: $($allFlows.Count)" -ForegroundColor Green
    Write-Host "Enabled Flows: $(($allFlows | Where-Object {$_.Enabled -eq $true}).Count)" -ForegroundColor Green
    Write-Host "Disabled Flows: $(($allFlows | Where-Object {$_.Enabled -eq $false}).Count)" -ForegroundColor Yellow
    Write-Host "Running Flows: $(($allFlows | Where-Object {$_.State -eq 'Started'}).Count)" -ForegroundColor Green
    Write-Host "Stopped Flows: $(($allFlows | Where-Object {$_.State -eq 'Stopped'}).Count)" -ForegroundColor Yellow
    
    # Group by environment
    Write-Host "`nFlows by Environment:" -ForegroundColor Cyan
    $flowsByEnv = $allFlows | Group-Object EnvironmentDisplayName | Sort-Object Count -Descending
    foreach ($group in $flowsByEnv) {
        Write-Host "  $($group.Name): $($group.Count) flows" -ForegroundColor White
    }

    # Export to Excel with multiple sheets
    $exportPath = "PowerPlatformFlows_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
    
    # Create summary data
    Write-Host "Creating summary report..." -ForegroundColor Cyan
    
    # Environment Summary
    $envSummary = $allFlows | Group-Object EnvironmentDisplayName | ForEach-Object {
        $envFlows = $_.Group
        [PSCustomObject]@{
            EnvironmentName = $_.Name
            TotalFlows = $_.Count
            EnabledFlows = ($envFlows | Where-Object {$_.Enabled -eq $true}).Count
            DisabledFlows = ($envFlows | Where-Object {$_.Enabled -eq $false}).Count
            RunningFlows = ($envFlows | Where-Object {$_.State -eq "Started"}).Count
            StoppedFlows = ($envFlows | Where-Object {$_.State -eq "Stopped"}).Count
            UniqueCreators = ($envFlows | Select-Object CreatedBy -Unique).Count
            LastModified = ($envFlows | Sort-Object LastModifiedTime -Descending | Select-Object -First 1).LastModifiedTime
        }
    }
    
    # Creator Summary
    $creatorSummary = $allFlows | Group-Object CreatedBy | ForEach-Object {
        $creatorFlows = $_.Group
        [PSCustomObject]@{
            CreatedBy = $_.Name
            TotalFlows = $_.Count
            EnabledFlows = ($creatorFlows | Where-Object {$_.Enabled -eq $true}).Count
            DisabledFlows = ($creatorFlows | Where-Object {$_.Enabled -eq $false}).Count
            Environments = ($creatorFlows | Select-Object EnvironmentDisplayName -Unique).Count
            LastActivity = ($creatorFlows | Sort-Object LastModifiedTime -Descending | Select-Object -First 1).LastModifiedTime
        }
    } | Sort-Object TotalFlows -Descending
    
    # Trigger Type Summary
    $triggerSummary = $allFlows | Group-Object TriggerType | ForEach-Object {
        [PSCustomObject]@{
            TriggerType = $_.Name
            FlowCount = $_.Count
            Percentage = [math]::Round(($_.Count / $allFlows.Count) * 100, 2)
        }
    } | Sort-Object FlowCount -Descending
    
    # Overall Summary
    $overallSummary = [PSCustomObject]@{
        Metric = @(
            "Total Environments",
            "Total Flows",
            "Enabled Flows", 
            "Disabled Flows",
            "Running Flows",
            "Stopped Flows",
            "Unique Creators",
            "Report Generated"
        )
        Value = @(
            $environments.Count,
            $allFlows.Count,
            ($allFlows | Where-Object {$_.Enabled -eq $true}).Count,
            ($allFlows | Where-Object {$_.Enabled -eq $false}).Count,
            ($allFlows | Where-Object {$_.State -eq "Started"}).Count,
            ($allFlows | Where-Object {$_.State -eq "Stopped"}).Count,
            ($allFlows | Select-Object CreatedBy -Unique).Count,
            (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        )
    }
    
    # Export to Excel with multiple worksheets
    try {
        # Main flow data
        $allFlows | Export-Excel -Path $exportPath -WorksheetName "All Flows" -AutoSize -AutoFilter -FreezeTopRow
        
        # Summary sheets
        $overallSummary | Export-Excel -Path $exportPath -WorksheetName "Overall Summary" -AutoSize -Append
        $envSummary | Export-Excel -Path $exportPath -WorksheetName "Environment Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        $creatorSummary | Export-Excel -Path $exportPath -WorksheetName "Creator Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        $triggerSummary | Export-Excel -Path $exportPath -WorksheetName "Trigger Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        
        Write-Host "Results exported to Excel file: $exportPath" -ForegroundColor Green
        Write-Host "Excel file contains the following worksheets:" -ForegroundColor Cyan
        Write-Host "  - All Flows: Complete flow inventory" -ForegroundColor White
        Write-Host "  - Overall Summary: High-level statistics" -ForegroundColor White
        Write-Host "  - Environment Summary: Breakdown by environment" -ForegroundColor White
        Write-Host "  - Creator Summary: Breakdown by flow creator" -ForegroundColor White
        Write-Host "  - Trigger Summary: Breakdown by trigger type" -ForegroundColor White
        
    } catch {
        Write-Warning "Failed to create Excel file. Falling back to CSV export: $_"
        # Fallback to CSV
        $allFlows | Export-Csv -Path "PowerPlatformFlows_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation -Encoding UTF8
    }

    # Display sample of results
    if ($allFlows.Count -gt 0) {
        Write-Host "`nSample of flows found:" -ForegroundColor Cyan
        $allFlows | Select-Object -First 5 | Format-Table -AutoSize
    }

} catch {
    Write-Error "Script execution failed: $_"
} finally {
    # Cleanup modules (optional - comment out if you want to keep modules installed)
    Write-Host "`nCleaning up modules..." -ForegroundColor Cyan
    # Remove-RequiredModules -modules $requiredModules
    Write-Host "Cleanup completed. Modules left installed for future use." -ForegroundColor Green
}