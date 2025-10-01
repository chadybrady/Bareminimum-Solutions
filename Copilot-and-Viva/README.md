# Copilot and Viva Scripts

This directory contains PowerShell scripts for managing Microsoft Copilot and Viva suite features.

## Scripts

### disableVivaFeatures
**File**: `disableVivaFeatures.ps1`

Comprehensive script to disable various Viva and Copilot features across your Microsoft 365 tenant. This script helps organizations control the rollout and availability of AI-powered features.

**Features Controlled**:
- **Viva Pulse**: CustomizationControl, PulseConversation, CopilotInVivaPulse, PulseExpWithM365Copilot, PulseDelegation
- **Viva Goals**: CopilotInVivaGoals
- **Viva Glint**: CopilotInVivaGlint
- **Viva Engage**: AISummarization, CopilotInVivaEngage
- **Viva Insights**: Reflection, CopilotDashboard, DigestWelcomeEmail, AutoCxoIdentification, MeetingCostAndQuality, CopilotDashboardDelegation, AnalystReportPublish, CopilotInVivaInsights, AdvancedInsights, CopilotChatInVivaInsights

**Teams App Blocking**:
- Blocks Viva suite apps (Learning, Pulse, etc.)
- Blocks Copilot apps (Copilot App, Copilot for Sales, Copilot for Service, Copilot for Studio)

**Prerequisites**: 
- `ExchangeOnlineManagement`
- `MicrosoftTeams`

**Required Permissions**:
- Exchange Online Administrator
- Teams Administrator

**Usage**:
```powershell
.\disableVivaFeatures.ps1
```

The script will:
1. Prompt to install required PowerShell modules (optional)
2. Connect to Exchange Online
3. Remove existing feature policies for the specified features
4. Create new policies to disable all Viva and Copilot features for everyone
5. Connect to Microsoft Teams
6. Block Viva and Copilot apps in Teams

## Important Notes

⚠️ **Tenant-Wide Impact**: This script disables features for all users in your tenant. Consider:
- Impact on user productivity and adoption plans
- Communication to users before disabling features
- Testing in a non-production environment first
- Your organization's policies regarding AI features

## Customization

To enable selective features or target specific users:
1. Modify the `$FeatureIDs` array to include only features you want to disable
2. Change the `-Everyone` parameter to specific groups or users
3. Adjust the `$VivaApps` and `$CopilotApps` arrays to control app blocking

## Cleanup

The script includes automatic cleanup of existing policies before creating new ones to prevent conflicts and ensure clean policy application.
