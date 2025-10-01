# Copilot and Viva Scripts

Scripts for managing Microsoft Copilot and Viva suite features and applications.

## Scripts

### disableVivaFeatures.ps1

Comprehensive script to disable various Viva and Copilot features across your Microsoft 365 tenant. This script:
- Removes existing Viva feature policies
- Disables Copilot features in Viva apps
- Blocks Viva and Copilot apps in Microsoft Teams
- Configures feature policies for multiple Viva modules

**Features Managed**:
- Viva Pulse (with Copilot)
- Viva Goals (with Copilot)
- Viva Glint (with Copilot)
- Viva Engage (with Copilot and AI features)
- Viva Insights (with Copilot and advanced features)
- Viva Learning

**Prerequisites**:
- `ExchangeOnlineManagement` module
- `MicrosoftTeams` module
- Global Administrator or Exchange Administrator rights

**Usage**:
```powershell
.\disableVivaFeatures.ps1
```

The script will prompt to install required modules if not present.

## Important Notes

⚠️ **Impact Warning**: This script makes organization-wide changes to Viva and Copilot features. 

**Before Running**:
1. Review your organization's requirements for Viva features
2. Test in a non-production environment first
3. Ensure you have proper administrative permissions
4. Consider backing up current configurations

**What Gets Disabled**:
- All Copilot features within Viva applications
- AI summarization features
- Viva app installations in Teams
- Premium insight features

💡 **Recommendation**: Review the script and comment out any features you want to keep enabled before running.
