# Autopilot Scripts

This directory contains PowerShell scripts for Windows Autopilot device management and enrollment.

## Scripts

### HW-Hash-Upload/UploadDeviceHash
**File**: `UploadDeviceHash.ps1`

Retrieves Windows Autopilot hardware hash information and uploads it online for device registration. This script simplifies the process of enrolling devices into Windows Autopilot.

**Features**:
- Automatic installation of Get-WindowsAutopilotInfo script
- TLS 1.2 secure connection
- Direct online upload with credential prompt
- Simple execution process

**Prerequisites**: 
- Administrator privileges
- Internet connection
- Intune Administrator rights or higher

**Usage**:
```powershell
.\UploadDeviceHash.ps1
```

The script will:
1. Set security protocol to TLS 1.2
2. Set execution policy for the current session
3. Install Get-WindowsAutopilotInfo script
4. Retrieve hardware hash and prompt for credentials
5. Upload device information to Autopilot

## Important Notes

- User must have at least Intune Administrator rights
- Device must be connected to the internet
- Credential prompt will appear during execution
- Hardware hash is automatically uploaded to the tenant

## Related Documentation

- [Windows Autopilot Overview](https://docs.microsoft.com/en-us/mem/autopilot/windows-autopilot)
- [Get-WindowsAutoPilotInfo Script](https://www.powershellgallery.com/packages/Get-WindowsAutoPilotInfo)
