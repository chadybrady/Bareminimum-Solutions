# Autopilot Scripts

Scripts for Windows Autopilot device management and enrollment.

## Scripts

### HW-Hash-Upload
**File**: `UploadDeviceHash.ps1`

Uploads hardware hash information for Windows Autopilot enrollment. This script:
- Installs the Get-WindowsAutopilotInfo script
- Retrieves Windows Autopilot hardware information
- Uploads device information directly to Intune

**Prerequisites**:
- Intune Administrator rights (minimum)
- Internet connectivity

**Usage**:
```powershell
.\UploadDeviceHash.ps1
```

The script will prompt for credentials and handle the device registration automatically.

## Important Notes

⚠️ **Permissions Required**: You must have at least Intune Administrator rights to run these scripts.

💡 **Best Practices**:
- Run on the device being enrolled
- Ensure stable internet connection
- Verify device appears in Autopilot device list after upload
