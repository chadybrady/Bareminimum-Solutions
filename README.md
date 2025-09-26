# Bareminimum Solutions

A collection of PowerShell scripts and automation solutions for Microsoft 365, Azure, and related services.

## Repository Structure

### 🚁 Autopilot
Scripts for Windows Autopilot device management and enrollment.
- **HW-Hash-Upload**: Hardware hash upload utilities

### 🤖 Copilot-and-Viva
Scripts for Microsoft Copilot and Viva suite management.
- **disableVivaFeatures.ps1**: Disable various Viva features across the tenant

### 🔐 Entra-ID
Azure Active Directory (Entra ID) management scripts.
- **Accounts/Create-Break-Glass-Accounts**: Emergency access account creation
- **Conditional-Access/Create-CA-Baseline**: Baseline conditional access policies

### 📊 Excel
Excel file manipulation and conversion utilities.
- **ConvertCSVToExcel.ps1**: Convert CSV files to Excel format

### 📱 Intune
Microsoft Intune device management scripts.
- **Rename**: Device renaming utilities for Android devices

### 📊 Monitoring
Monitoring and reporting scripts for various Microsoft services.
- **Entra**: Entra ID monitoring scripts
  - **Users-Get-All**: Retrieve all user information
  - **Enterprise-Applications/Enterprise-Secrets-Monitoring**: Monitor enterprise app secrets
- **Intune**: Intune monitoring scripts
  - **Connectors/Apple-Token-Monitoring**: Monitor Apple connector tokens

### ⚡ Power-Platform
Microsoft Power Platform (Power Apps, Power Automate) management scripts.
- **Get_PP_Apps**: Retrieve Power Apps information
- **Get_PP_Flows**: Retrieve Power Automate flows information
- **Gather-System**: Comprehensive Power Platform inventory and reporting

## Prerequisites

Most scripts require one or more of the following PowerShell modules:
- `Microsoft.Graph`
- `Microsoft.Graph.Beta`
- `Microsoft.PowerApps.Administration.PowerShell`
- `MicrosoftTeams`
- `ExchangeOnlineManagement`
- `Microsoft.Entra`

## Usage

1. Install required PowerShell modules for the script you want to run
2. Connect to the appropriate service (Azure AD, Exchange Online, etc.)
3. Run the script with appropriate permissions

## Contributing

When adding new scripts:
1. Follow the existing folder structure and naming conventions
2. Use kebab-case for folder names (e.g., `My-New-Feature`)
3. Include appropriate comments and documentation in scripts
4. Test scripts thoroughly before committing

## Security Note

These scripts often require administrative privileges. Always review and understand scripts before running them in production environments.