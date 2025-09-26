# Monitoring Scripts

This directory contains PowerShell scripts for monitoring various Microsoft 365 and Azure services.

## Entra ID Monitoring

### Users-Get-All
**File**: `EntraID-GetAllUsers.ps1`

Retrieves comprehensive information about all users in the Entra ID tenant.

### Enterprise-Applications/Enterprise-Secrets-Monitoring
**File**: `enterpriseappmonitoringsecret.ps1`

Monitors enterprise applications for expiring secrets and certificates. Essential for maintaining application security and preventing service disruptions.

## Intune Monitoring

### Connectors/Apple-Token-Monitoring
**File**: `applemonitoring.ps1`

Monitors Apple connector tokens in Microsoft Intune. These tokens are critical for iOS device management and need regular monitoring to prevent expiration.

## Usage

1. Install required PowerShell modules for the specific monitoring script
2. Connect to the appropriate service with monitoring/read permissions
3. Run scripts regularly (consider scheduling) for ongoing monitoring
4. Review outputs for any items requiring attention

## Scheduling Recommendations

Consider scheduling these monitoring scripts to run regularly:
- **Daily**: Secret and certificate expiration monitoring
- **Weekly**: User account reviews
- **Monthly**: Comprehensive connector token checks

Use Windows Task Scheduler, Azure Automation, or similar tools for automated execution.