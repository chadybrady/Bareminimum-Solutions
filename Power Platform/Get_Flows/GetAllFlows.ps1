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
    
    # Debug: List environments found
    if ($environments.Count -eq 0) {
        Write-Warning "No environments found! This could indicate:"
        Write-Host "  1. Authentication issues" -ForegroundColor Yellow
        Write-Host "  2. Insufficient permissions" -ForegroundColor Yellow
        Write-Host "  3. No Power Platform environments in tenant" -ForegroundColor Yellow
        return
    } else {
        Write-Host "Environments found:" -ForegroundColor Cyan
        foreach ($env in $environments) {
            Write-Host "  - $($env.DisplayName) ($($env.EnvironmentName))" -ForegroundColor White
        }
    }

    # Initialize results array
    $allFlows = @()

    # Process each environment
    foreach ($env in $environments) {
        Write-Host "Processing environment: $($env.DisplayName) ($($env.EnvironmentName))" -ForegroundColor Cyan
        
        try {
            # Get flows for this environment
            Write-Host "  Querying flows..." -ForegroundColor Gray
            $flows = Get-AdminFlow -EnvironmentName $env.EnvironmentName
            
            if ($flows) {
                Write-Host "  Found $($flows.Count) flows" -ForegroundColor Green
                
                # Debug: Show first flow details
                if ($flows.Count -gt 0) {
                    $firstFlow = $flows[0]
                    Write-Host "  Sample flow details:" -ForegroundColor Gray
                    Write-Host "    FlowName: $($firstFlow.FlowName)" -ForegroundColor Gray
                    Write-Host "    DisplayName: $($firstFlow.DisplayName)" -ForegroundColor Gray
                    Write-Host "    CreatedBy: $($firstFlow.CreatedBy)" -ForegroundColor Gray
                    Write-Host "    State: $($firstFlow.State)" -ForegroundColor Gray
                }
                
                # Add environment info to each flow
                foreach ($flow in $flows) {
                    # Handle flows without owners (orphaned flows)
                    $createdBy = if ($flow.CreatedBy -and $flow.CreatedBy.displayName) {
                        $flow.CreatedBy.displayName
                    } elseif ($flow.CreatedBy -and $flow.CreatedBy.userPrincipalName) {
                        $flow.CreatedBy.userPrincipalName
                    } else {
                        "** ORPHANED FLOW - No Owner **"
                    }
                    
                    # Convert all values to strings to avoid Excel display issues
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
                    }
                    $allFlows += $flowInfo
                }
            } else {
                Write-Host "  No flows found in this environment" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Failed to retrieve flows from environment $($env.DisplayName): $_"
            Write-Host "  Error details: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Display summary statistics
    Write-Host "`nFlow Inventory Summary:" -ForegroundColor Cyan
    Write-Host "Total Environments: $($environments.Count)" -ForegroundColor Green
    Write-Host "Total Flows Found: $($allFlows.Count)" -ForegroundColor Green
    Write-Host "Enabled Flows: $(($allFlows | Where-Object {$_.Enabled -eq 'True'}).Count)" -ForegroundColor Green
    Write-Host "Disabled Flows: $(($allFlows | Where-Object {$_.Enabled -eq 'False'}).Count)" -ForegroundColor Yellow
    Write-Host "Running Flows: $(($allFlows | Where-Object {$_.State -eq 'Started'}).Count)" -ForegroundColor Green
    Write-Host "Stopped Flows: $(($allFlows | Where-Object {$_.State -eq 'Stopped'}).Count)" -ForegroundColor Yellow
    Write-Host "Orphaned Flows: $(($allFlows | Where-Object {$_.IsOrphaned -eq 'True'}).Count)" -ForegroundColor Red
    Write-Host "Flows with Owners: $(($allFlows | Where-Object {$_.IsOrphaned -eq 'False'}).Count)" -ForegroundColor Green
    
    # Display orphaned flows warning if any exist
    $orphanedCount = ($allFlows | Where-Object {$_.IsOrphaned -eq 'True'}).Count
    if ($orphanedCount -gt 0) {
        Write-Host "`n⚠️  WARNING: Found $orphanedCount orphaned flows without owners!" -ForegroundColor Red
        Write-Host "   These flows may need administrative attention or cleanup." -ForegroundColor Yellow
    }
    
    # Group by environment
    Write-Host "`nFlows by Environment:" -ForegroundColor Cyan
    $flowsByEnv = $allFlows | Group-Object EnvironmentDisplayName | Sort-Object Count -Descending
    foreach ($group in $flowsByEnv) {
        $orphanedInEnv = ($group.Group | Where-Object {$_.IsOrphaned -eq 'True'}).Count
        $orphanedText = if ($orphanedInEnv -gt 0) { " ($orphanedInEnv orphaned)" } else { "" }
        Write-Host "  $($group.Name): $($group.Count) flows$orphanedText" -ForegroundColor White
    }

    # Export to Excel with multiple sheets
    $exportPath = "PowerPlatformFlows_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
    
    # Create summary data
    Write-Host "Creating summary report..." -ForegroundColor Cyan
    
    # Environment Summary
    $envSummary = $allFlows | Group-Object EnvironmentDisplayName | ForEach-Object {
        $envFlows = $_.Group
        [PSCustomObject]@{
            EnvironmentName = [string]$_.Name
            TotalFlows = [string]$_.Count
            EnabledFlows = [string]($envFlows | Where-Object {$_.Enabled -eq "True"}).Count
            DisabledFlows = [string]($envFlows | Where-Object {$_.Enabled -eq "False"}).Count
            RunningFlows = [string]($envFlows | Where-Object {$_.State -eq "Started"}).Count
            StoppedFlows = [string]($envFlows | Where-Object {$_.State -eq "Stopped"}).Count
            OrphanedFlows = [string]($envFlows | Where-Object {$_.IsOrphaned -eq "True"}).Count
            UniqueCreators = [string]($envFlows | Where-Object {$_.IsOrphaned -eq "False"} | Select-Object CreatedBy -Unique).Count
            LastModified = if ($envFlows) { [string]($envFlows | Sort-Object LastModifiedTime -Descending | Select-Object -First 1).LastModifiedTime } else { "" }
        }
    }
    
    # Creator Summary (excluding orphaned flows)
    $creatorSummary = $allFlows | Where-Object {$_.IsOrphaned -eq "False"} | Group-Object CreatedBy | ForEach-Object {
        $creatorFlows = $_.Group
        [PSCustomObject]@{
            CreatedBy = [string]$_.Name
            TotalFlows = [string]$_.Count
            EnabledFlows = [string]($creatorFlows | Where-Object {$_.Enabled -eq "True"}).Count
            DisabledFlows = [string]($creatorFlows | Where-Object {$_.Enabled -eq "False"}).Count
            Environments = [string]($creatorFlows | Select-Object EnvironmentDisplayName -Unique).Count
            LastActivity = if ($creatorFlows) { [string]($creatorFlows | Sort-Object LastModifiedTime -Descending | Select-Object -First 1).LastModifiedTime } else { "" }
        }
    } | Sort-Object { [int]$_.TotalFlows } -Descending
    
    # Orphaned Flows Summary
    $orphanedFlows = $allFlows | Where-Object {$_.IsOrphaned -eq "True"}
    $orphanedSummary = if ($orphanedFlows.Count -gt 0) {
        $orphanedFlows | Group-Object EnvironmentDisplayName | ForEach-Object {
            $orphanFlows = $_.Group
            [PSCustomObject]@{
                EnvironmentName = [string]$_.Name
                OrphanedFlows = [string]$_.Count
                EnabledOrphaned = [string]($orphanFlows | Where-Object {$_.Enabled -eq "True"}).Count
                DisabledOrphaned = [string]($orphanFlows | Where-Object {$_.Enabled -eq "False"}).Count
                RunningOrphaned = [string]($orphanFlows | Where-Object {$_.State -eq "Started"}).Count
                StoppedOrphaned = [string]($orphanFlows | Where-Object {$_.State -eq "Stopped"}).Count
                OldestOrphaned = if ($orphanFlows) { [string]($orphanFlows | Sort-Object CreatedTime | Select-Object -First 1).CreatedTime } else { "" }
                NewestOrphaned = if ($orphanFlows) { [string]($orphanFlows | Sort-Object CreatedTime -Descending | Select-Object -First 1).CreatedTime } else { "" }
            }
        }
    } else {
        @([PSCustomObject]@{
            EnvironmentName = "No orphaned flows found"
            OrphanedFlows = "0"
            EnabledOrphaned = "0"
            DisabledOrphaned = "0"
            RunningOrphaned = "0"
            StoppedOrphaned = "0"
            OldestOrphaned = ""
            NewestOrphaned = ""
        })
    }
    
    # Trigger Type Summary
    $triggerSummary = $allFlows | Group-Object TriggerType | ForEach-Object {
        [PSCustomObject]@{
            TriggerType = [string]$_.Name
            FlowCount = [string]$_.Count
            Percentage = [string]([math]::Round(($_.Count / $allFlows.Count) * 100, 2))
        }
    } | Sort-Object { [int]$_.FlowCount } -Descending
    
    # Overall Summary
    $overallSummary = @()
    $overallSummary += [PSCustomObject]@{ Metric = "Total Environments"; Value = $environments.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Total Flows"; Value = $allFlows.Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Enabled Flows"; Value = ($allFlows | Where-Object {$_.Enabled -eq $true}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Disabled Flows"; Value = ($allFlows | Where-Object {$_.Enabled -eq $false}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Running Flows"; Value = ($allFlows | Where-Object {$_.State -eq "Started"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Stopped Flows"; Value = ($allFlows | Where-Object {$_.State -eq "Stopped"}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Orphaned Flows"; Value = ($allFlows | Where-Object {$_.IsOrphaned -eq $true}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Flows with Owners"; Value = ($allFlows | Where-Object {$_.IsOrphaned -eq $false}).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Unique Creators"; Value = ($allFlows | Where-Object {$_.IsOrphaned -eq $false} | Select-Object CreatedBy -Unique).Count.ToString() }
    $overallSummary += [PSCustomObject]@{ Metric = "Report Generated"; Value = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }
    
    # Export to Excel with multiple worksheets
    try {
        # Main flow data
        $allFlows | Export-Excel -Path $exportPath -WorksheetName "All Flows" -AutoSize -AutoFilter -FreezeTopRow
        
        # Summary sheets
        $overallSummary | Export-Excel -Path $exportPath -WorksheetName "Overall Summary" -AutoSize -Append
        $envSummary | Export-Excel -Path $exportPath -WorksheetName "Environment Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        $creatorSummary | Export-Excel -Path $exportPath -WorksheetName "Creator Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        $orphanedSummary | Export-Excel -Path $exportPath -WorksheetName "Orphaned Flows" -AutoSize -AutoFilter -FreezeTopRow -Append
        $triggerSummary | Export-Excel -Path $exportPath -WorksheetName "Trigger Summary" -AutoSize -AutoFilter -FreezeTopRow -Append
        
        Write-Host "Results exported to Excel file: $exportPath" -ForegroundColor Green
        Write-Host "Excel file contains the following worksheets:" -ForegroundColor Cyan
        Write-Host "  - All Flows: Complete flow inventory (includes orphaned flows)" -ForegroundColor White
        Write-Host "  - Overall Summary: High-level statistics" -ForegroundColor White
        Write-Host "  - Environment Summary: Breakdown by environment (includes orphaned count)" -ForegroundColor White
        Write-Host "  - Creator Summary: Breakdown by flow creator (excludes orphaned)" -ForegroundColor White
        Write-Host "  - Orphaned Flows: Summary of flows without owners" -ForegroundColor White
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
    # Cleanup modules - ALWAYS runs even if script fails
    Write-Host "`nCleaning up modules..." -ForegroundColor Cyan
    Remove-RequiredModules -modules $requiredModules
    Write-Host "Module cleanup completed." -ForegroundColor Green
}