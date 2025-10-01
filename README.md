# Bareminimum Solutions 🚀

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/chadybrady/Bareminimum-Solutions/graphs/commit-activity)

A collection of PowerShell scripts and automation solutions for Microsoft 365, Azure, and related services.

> **⚠️ Security Notice**: These scripts often require administrative privileges. Always review and understand scripts before running them in production environments.

## 📑 Table of Contents

- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Repository Structure

### 🚁 Autopilot
Scripts for Windows Autopilot device management and enrollment.
- **[HW-Hash-Upload](Autopilot/README.md)**: Hardware hash upload utilities for device registration

### 🤖 Copilot-and-Viva
Scripts for Microsoft Copilot and Viva suite management.
- **[disableVivaFeatures.ps1](Copilot-and-Viva/README.md)**: Disable various Viva features across the tenant

### 🔐 Entra-ID
Azure Active Directory (Entra ID) management scripts.
- **[Accounts/Create-Break-Glass-Accounts](Entra-ID/README.md)**: Emergency access account creation
- **[Conditional-Access/Create-CA-Baseline](Entra-ID/README.md)**: Baseline conditional access policies

### 📊 Excel
Excel file manipulation and conversion utilities.
- **[ConvertCSVToExcel.ps1](Excel/README.md)**: Convert CSV files to Excel format

### 📱 Intune
Microsoft Intune device management scripts.
- **[Rename](Intune/README.md)**: Device renaming utilities for Android devices
- **[Win32-ForceReinstallApp](Intune/README.md)**: Force reinstall of Win32 apps by cleaning registry and artifacts

### 📊 Monitoring
Monitoring and reporting scripts for various Microsoft services.
- **[Entra](Monitoring/README.md)**: Entra ID monitoring scripts
  - **Users-Get-All**: Retrieve all user information
  - **Enterprise-Applications/Enterprise-Secrets-Monitoring**: Monitor enterprise app secrets
- **[Intune](Monitoring/README.md)**: Intune monitoring scripts
  - **Connectors/Apple-Token-Monitoring**: Monitor Apple connector tokens

### ⚡ Power-Platform
Microsoft Power Platform (Power Apps, Power Automate) management scripts.
- **[Get-PP-Apps](Power-Platform/README.md)**: Retrieve Power Apps information
- **[Get-PP-Flows](Power-Platform/README.md)**: Retrieve Power Automate flows information
- **[Gather-System](Power-Platform/README.md)**: Comprehensive Power Platform inventory and reporting

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

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

When adding new scripts:
1. Follow the existing folder structure and naming conventions
2. Use kebab-case for folder names (e.g., `My-New-Feature`)
3. Include appropriate comments and documentation in scripts
4. Add a README.md file in the script's directory
5. Update the main README.md with a link to your script
6. Test scripts thoroughly before committing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Community contributors and testers
- Microsoft documentation and examples
- Open-source PowerShell community

## Support

For issues, questions, or contributions, please use the GitHub Issues page.

---

**Created and maintained by the Bareminimum Solutions team** 💙