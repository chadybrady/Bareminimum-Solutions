# Intune Scripts

This directory contains PowerShell scripts for managing Microsoft Intune and device management.

## Scripts

### Rename/AndroidRenameByDeviceGroups
**File**: `AndroidRenameByDeviceGroups.ps1`

Bulk rename Android devices to a standardized format (Android-SERIAL) based on Azure AD group membership. Features:
- Query devices by Azure AD group membership
- Standardized naming convention using serial numbers
- Progress tracking and detailed logging
- Batch processing with error handling

**Prerequisites**: 
- `Microsoft.Graph.Beta`

**Required Permissions**:
- `DeviceManagementManagedDevices.PrivilegedOperations.All`
- `Group.Read.All`
- `GroupMember.Read.All`
- `Device.Read.All`

### Win32-ForceReinstallApp
**File**: `Win32ForceReinstallApp.ps1`

Forces reinstall of Intune Win32 apps by removing registry entries and artifacts. Based on research from Johan Arwidmark and Rudy Ooms. Features:
- Comprehensive registry cleanup
- GRS (Global Re-evaluation Schedule) hash discovery
- User SID-specific cleanup
- File and folder artifact removal
- Service restart for Intune Management Extension

**Prerequisites**: 
- Administrator privileges
- Intune Management Extension installed

**Important**: Must manually clean up detection rule artifacts after running the script (files, registry keys, MSI products, etc.)

## Usage

1. Install required PowerShell modules for the script you want to run
2. Connect to Microsoft Graph with appropriate permissions
3. Run the script with the necessary parameters
4. Review output for any errors or issues

## Security Note

These scripts require administrative privileges and can modify device configurations. Always test in a non-production environment first.
