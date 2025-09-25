<#
.SYNOPSIS
    Exports all Power Automate flows and their connectors in a flat CSV format.

.DESCRIPTION
    Retrieves all flows from the tenant and outputs one row per connector per flow. Flows without connectors will appear with empty connector columns.

.PARAMETER FilePath
    Path for CSV export. Defaults to "./FlowsExport.csv"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)] [string]$FilePath = "./FlowsExport.csv"
)

$ErrorActionPreference = "Stop"

# Function for colored output
function Write-ColoredMessage {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Function to install required modules
function Install-RequiredModules {
    $modules = @("Microsoft.PowerApps.Administration.PowerShell", "Microsoft.Entra")
    foreach ($module in $modules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-ColoredMessage "Installing $module ..." "Cyan"
            Install-Module -Name $module -AllowClobber -Force -Scope CurrentUser
        }
    }
}

# Function to connect services
function Connect-Services {
    Write-ColoredMessage "Connecting to Power Platform..." "Green"
    Add-PowerAppsAccount
    Write-ColoredMessage "Connecting to Microsoft Entra..." "Green"
    Connect-Entra -Scopes 'User.Read.All'
}

# Function to get user details
function Get-UserDetails {
    param([string]$UserId)
    if (-not $UserId) {
        return @{DisplayName = "System/Unknown"; UserPrincipalName = "N/A"}
    }
    try {
        $user = Get-EntraUser -UserId $UserId -Property Id,DisplayName,UserPrincipalName -ErrorAction Stop
        return @{DisplayName = $user.DisplayName; UserPrincipalName = $user.UserPrincipalName}
    }
    catch {
        try {
            $sp = Get-EntraServicePrincipal -ServicePrincipalId $UserId -Property Id,DisplayName,AppId -ErrorAction Stop
            return @{DisplayName = "$($sp.DisplayName) (Service Principal)"; UserPrincipalName = $sp.AppId}
        }
        catch {
            return @{DisplayName = "Unknown Creator"; UserPrincipalName = $UserId}
        }
    }
}

# Function to disconnect services
function Disconnect-Services {
    Write-ColoredMessage "Disconnecting from Entra..." "Yellow"
    Disconnect-Entra
    Write-ColoredMessage "Disconnecting from PowerApps..." "Yellow"
    Remove-PowerAppsAccount
}

# Main execution
try {
    Write-ColoredMessage "Export Power Automate Flows & Connectors" "Green"
    Install-RequiredModules
    Connect-Services

    Write-ColoredMessage "Retrieving flows ..." "Cyan"
    $Flows = Get-AdminFlow
    $ConnectorExport = @()
    $Count = 0

    foreach ($Flow in $Flows) {
        $Count++
        Write-Progress -Activity "Processing Flows" -Status "Flow $Count of $($Flows.Count): $($Flow.DisplayName)" -PercentComplete (($Count / $Flows.Count) * 100)
        
        # Try to get connectors (from initial or detailed info)
        try {
            $Connectors = $null
            if ($Flow.Internal.properties.connectionReferences) {
                $Connectors = $Flow.Internal.properties.connectionReferences
            } else {
                $FlowInfo = Get-AdminFlow -FlowName $Flow.FlowName -EnvironmentName $Flow.EnvironmentName
                $Connectors = $FlowInfo.Internal.properties.connectionReferences
            }
        }
        catch {
            $Connectors = $null
        }

        # Get user info
        $UserId = $Flow.CreatedBy.UserID
        $User = Get-UserDetails -UserId $UserId

        if ($Connectors -and $Connectors.PSObject.Properties.Count -gt 0) {
            foreach ($Connector in $Connectors.PSObject.Properties) {
                $ConnectorExport += [PSCustomObject]@{
                    FlowID            = $Flow.FlowName
                    FlowName          = $Flow.DisplayName
                    Enabled           = $Flow.Enabled
                    Environment       = $Flow.EnvironmentName
                    UserID            = $UserId
                    UserDisplayName   = $User.DisplayName
                    UserPrincipalName = $User.UserPrincipalName
                    ConnectorName     = $Connector.Name
                    ConnectorType     = $Connector.Value.ConnectorName
                    ConnectorDisplay  = $Connector.Value.DisplayName
                }
            }
        } else {
            # Export flows with no connectors for completeness
            $ConnectorExport += [PSCustomObject]@{
                FlowID            = $Flow.FlowName
                FlowName          = $Flow.DisplayName
                Enabled           = $Flow.Enabled
                Environment       = $Flow.EnvironmentName
                UserID            = $UserId
                UserDisplayName   = $User.DisplayName
                UserPrincipalName = $User.UserPrincipalName
                ConnectorName     = ""
                ConnectorType     = ""
                ConnectorDisplay  = ""
            }
        }

        if ($Flows.Count -gt 50 -and $Count % 10 -eq 0) {
            Start-Sleep -Seconds 1
        }
    }

    # Export to CSV
    $ConnectorExport | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
    Write-ColoredMessage "Export completed: $FilePath" "Green"
    Write-ColoredMessage "Total rows exported: $($ConnectorExport.Count)" "Cyan"
}
catch {
    Write-ColoredMessage "Script failed: $($_.Exception.Message)" "Red"
}
finally {
    Disconnect-Services
    Write-ColoredMessage "Script completed." "Green"
}
