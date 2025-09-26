# Power Platform Scripts

This directory contains PowerShell scripts for managing Microsoft Power Platform components including Power Apps, Power Automate, and Power BI.

## Scripts

### Get-PP-Apps
**File**: `GetAllApps.ps1`

Exports Power Apps and their connectors to CSV format by environment. Features:
- Interactive environment selection
- Comprehensive app and connector information export
- Status updates during execution
- UTF-8 encoded CSV output

**Prerequisites**: 
- `Microsoft.PowerApps.Administration.PowerShell`
- `Microsoft.Entra`

### Get-PP-Flows
**File**: `GetAllFlows.ps1`

Retrieves and exports Power Automate flows information.

**Prerequisites**: 
- `Microsoft.PowerApps.Administration.PowerShell`

### Gather-System
**File**: `PP-GatherSystem.ps1`

Comprehensive Power Platform inventory and reporting system that:
- Gathers all Power Apps across environments
- Collects Power Automate flows with connector information
- Assigns connector tiers (Standard/Premium)
- Generates multiple CSV reports:
  - Individual Power Apps export
  - Individual Power Automate export
  - Combined platform report
  - Connector usage summary

**Prerequisites**: 
- `Microsoft.PowerApps.Administration.PowerShell`

## Usage Notes

1. Ensure you have the required PowerShell modules installed
2. Connect to Power Platform with appropriate administrative permissions
3. Scripts will prompt for environment selection where applicable
4. Output files are generated in the same directory as the script with timestamps