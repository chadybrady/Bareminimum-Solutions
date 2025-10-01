# Intune Scripts

Microsoft Intune device management and administration scripts.

## Scripts

### Rename/AndroidRenameByDeviceGroups.ps1

Bulk renames Android devices in Intune to follow a standardized naming convention (Android-SERIAL format). This script:
- Queries devices by Azure AD group membership
- Renames devices to `Android-{SerialNumber}` format
- Provides detailed progress reporting
- Exports comprehensive results to CSV

**Prerequisites**:
- `Microsoft.Graph.Beta` module
- Required Graph API permissions:
  - `DeviceManagementManagedDevices.PrivilegedOperations.All`
  - `Group.Read.All`
  - `GroupMember.Read.All`
  - `Device.Read.All`

**Usage**:
```powershell
# Edit the script to configure your Azure AD group IDs
$groupConfigs = @(
    @{ GroupId = "your-group-id"; Description = "Description" }
)

# Run the script
.\AndroidRenameByDeviceGroups.ps1
```

**Output**:
- CSV file with rename results (timestamp-based filename)
- Summary statistics (successful, failed, skipped)
- Sample of renamed devices in console

### Win32-ForceReinstallApp/Win32ForceReinstallApp.ps1

Forces reinstallation of a Win32 application deployed through Intune by cleaning up all associated registry entries, logs, and cached files. This script:
- Removes Intune Management Extension logs for the app
- Cleans registry entries for app detection and installation
- Removes cached content and staging files
- Restarts the Intune Management Extension service

**Prerequisites**:
- Local Administrator rights on the device
- Application ID from Intune (GUID)

**Usage**:
```powershell
.\Win32ForceReinstallApp.ps1
```

The script will prompt for the Application ID (GUID).

**Use Cases**:
- App installation failed and needs retry
- App shows as installed but isn't working
- Need to force app reinstallation without creating new deployment

⚠️ **Warning**: This script makes significant changes to system files and registry. Always:
- Back up important data first
- Test on non-production devices
- Understand the impact before running

## Important Notes

**Permissions**: Most scripts require administrative permissions in Intune and/or on the local device.

**Device Naming**: The Android rename script aligns with iOS naming conventions for consistency.

**Next Steps**: After device renames sync to Intune, update enrollment profiles to use the `{{DEVICETYPE}}-{{SERIAL}}` template for future enrollments.
