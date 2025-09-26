# Entra ID (Azure Active Directory) Scripts

This directory contains PowerShell scripts for managing Azure Active Directory (now called Microsoft Entra ID).

## Scripts

### Accounts/Create-Break-Glass-Accounts
**File**: `CreateEntraIDBreakTheGlass.ps1`

Creates emergency access (break-glass) accounts for Azure AD. These accounts provide emergency access to Azure AD when normal administrative access is unavailable.

**Prerequisites**: 
- `Microsoft.Entra`
- `Microsoft.Graph`

### Conditional-Access/Create-CA-Baseline
**File**: `CreateCaBaseline.ps1`

Creates a baseline set of Conditional Access policies for organizational security. Includes policies for:
- User risk-based access controls
- Multi-factor authentication requirements
- Password change requirements for high-risk users

**Prerequisites**: 
- `Microsoft.Entra`
- `Microsoft.Graph`
- `Microsoft.Graph.Identity.SignIns`

## Important Notes

⚠️ **Security Warning**: These scripts create security policies and administrative accounts. Always:
1. Review scripts thoroughly before execution
2. Test in a non-production environment first
3. Ensure you have proper permissions and backup access
4. Follow your organization's security policies and procedures

## Module Management

The scripts include automatic module installation and cleanup features. They will:
1. Install required modules if not present
2. Import necessary modules
3. Clean up and uninstall modules after execution (in some scripts)

Make sure you have appropriate permissions to install PowerShell modules.