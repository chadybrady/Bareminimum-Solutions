# Intune Configuration Testing System

## Overview
A comprehensive PowerShell tool that performs deep analysis of Microsoft Intune configurations and generates detailed reports comparing your setup against Microsoft best practices.

## Features

### 🔍 Deep Configuration Analysis
Unlike basic inventory tools, this solution performs **deep dive analysis** into each policy's settings:

#### Compliance Policies - Detailed Checks
- **Windows 10 Compliance:**
  - Password requirements (length, complexity, idle timeout)
  - BitLocker encryption enforcement
  - Secure Boot and TPM requirements
  - OS version enforcement
  - Antivirus and anti-spyware requirements
  - Firewall configuration
  - Device Threat Protection levels
  - Code Integrity checks

- **iOS Compliance:**
  - Passcode requirements and strength
  - OS version enforcement
  - Jailbreak detection

- **Android Compliance:**
  - Password/PIN requirements
  - Device encryption
  - OS version enforcement
  - Root detection

#### Configuration Profiles - Detailed Checks
- **Windows 10 Device Restrictions:**
  - Password policies (length, expiration, complexity)
  - Microsoft Defender settings (real-time monitoring, cloud protection)
  - SmartScreen configuration and bypass prevention
  - Windows Update notification levels
  - Privacy and storage settings

- **Windows Update for Business:**
  - Automatic update modes
  - Quality update deferral periods (with recommendations)
  - Feature update deferral periods
  - Microsoft Update Service (Office updates)
  - Driver update handling

- **iOS Device Restrictions:**
  - Passcode enforcement
  - App Store controls
  - Safari security settings
  - Camera and iCloud policies

- **Android Device Restrictions:**
  - Password requirements
  - Play Protect verification
  - Google backup controls
  - Security restrictions

- **Email Profiles:**
  - SSL/TLS encryption
  - S/MIME configuration

- **WiFi Profiles:**
  - Security type (WPA2/WPA3 Enterprise validation)
  - Auto-connect settings

- **VPN Profiles:**
  - Connection types
  - Split tunneling configuration

- **Endpoint Protection:**
  - BitLocker policies
  - Firewall rules
  - Windows Defender Application Guard
  - Virtualization-based security

### 📊 Microsoft Best Practices Framework
Tests against 10 key Microsoft security and configuration best practices:

1. **MFA Enforcement** - Conditional Access policies requiring MFA
2. **Windows Update Management** - Proper update ring configuration
3. **Minimum OS Version** - Enforcement of current OS versions
4. **Disk Encryption** - BitLocker/FileVault requirement
5. **Microsoft Defender Antivirus** - Antivirus policy configuration
6. **Password Requirements** - Strong password enforcement
7. **Mobile Application Management** - App protection policies
8. **Device Naming Convention** - Standardized Autopilot naming
9. **Security Baselines** - Microsoft security baseline implementation
10. **Compliance Grace Periods** - Scheduled compliance actions

### 📈 Test Categories (14 Areas)

1. **Microsoft Best Practices Assessment** - Compliance with Microsoft recommendations
2. **Conditional Access Policies** - Zero Trust authentication and authorization
3. **Device Compliance Policies** - Deep analysis of all compliance settings
4. **Configuration Profiles** - Detailed review of all configuration settings
5. **App Protection Policies (MAM)** - Mobile application management and data protection
6. **Application Management** - App inventory and assignment validation
7. **Endpoint Security Policies** - Antivirus, encryption, firewall, ASR policies
8. **Windows Autopilot Deployment Profiles** - Modern provisioning configuration
9. **Enrollment Settings** - Enrollment restrictions and configurations
10. **Assignment Filters** - Targeted deployment filters
11. **PowerShell Scripts & Proactive Remediations** - Automation and health scripts
12. **Role-Based Access Control (RBAC)** - Custom roles and delegations
13. **Enrollment Tokens & Certificates** - Apple/Android enrollment tokens with expiration monitoring
14. **Reports and Monitoring** - Access to managed devices and health monitoring

### 🎨 Enhanced HTML Reporting

The generated report includes:
- **Executive Summary Dashboard** with test statistics
- **Color-coded status indicators:**
  - ✅ Green (Pass) - Meets best practices
  - ⚠️ Yellow (Warning) - Needs attention
  - ❌ Red (Fail) - Critical issues
- **Detailed findings per policy** including:
  - ✓ Strengths - What's configured well
  - ❌ Issues - Critical problems requiring attention
  - 💡 Recommendations - Optimization opportunities
- **Professional styling** with hover effects and gradient cards
- **Mobile-responsive design**

## Requirements

### PowerShell Modules
The script automatically installs these modules if missing:
- `Microsoft.Graph.Authentication`
- `Microsoft.Graph.DeviceManagement`
- `Microsoft.Graph.DeviceManagement.Enrollment`

### Permissions Required
The following Microsoft Graph scopes are needed:
- `DeviceManagementConfiguration.Read.All`
- `DeviceManagementApps.Read.All`
- `DeviceManagementManagedDevices.Read.All`
- `DeviceManagementServiceConfig.Read.All`
- `Policy.Read.All` (for Conditional Access analysis)

## Usage

### Basic Usage
```powershell
.\Test-IntuneConfiguration.ps1
```

### Specify Output Path
```powershell
.\Test-IntuneConfiguration.ps1 -OutputPath "C:\Reports"
```

### Connect to Specific Tenant
```powershell
.\Test-IntuneConfiguration.ps1 -TenantId "your-tenant-id"
```

## Output

The script generates an HTML report with filename format:
```
IntuneConfigReport_YYYYMMDD_HHMMSS.html
```

### Sample Output Structure
```
Microsoft Intune Configuration Test Report
├── Summary Dashboard
│   ├── Total Tests
│   ├── Passed Tests
│   ├── Failed Tests
│   └── Warnings
├── Microsoft Best Practices Assessment
│   ├── MFA Enforcement
│   ├── Update Management
│   ├── Disk Encryption
│   └── ...
├── Device Compliance Policies
│   ├── Policy Inventory
│   └── Deep Analysis per Policy
│       ├── Strengths (✓)
│       ├── Issues (❌)
│       └── Settings Review
├── Configuration Profiles
│   ├── Profile Inventory
│   └── Deep Analysis per Profile
│       ├── Strengths (✓)
│       ├── Issues (❌)
│       └── Recommendations (💡)
└── [Additional Categories...]
```

## Interpretation Guide

### Status Meanings

**Pass (✅)**
- Configuration meets Microsoft best practices
- All critical security settings are properly configured
- Policy is assigned and active

**Warning (⚠️)**
- Configuration works but has optimization opportunities
- Some best practice recommendations not followed
- Minor security improvements possible
- Policy may not be assigned

**Fail (❌)**
- Critical security issues found
- Multiple best practices violations
- Configuration gaps that need immediate attention

### Common Issues and Recommendations

#### Compliance Policies
- **No BitLocker:** Data at rest is not encrypted
- **Weak passwords:** Passwords under 8 characters
- **No OS version enforcement:** Devices may run outdated/vulnerable OS
- **Antivirus not required:** Devices may be unprotected

#### Configuration Profiles
- **Real-time monitoring disabled:** Threats may not be detected
- **SmartScreen disabled:** Users exposed to malicious downloads
- **Long update deferrals:** Security patches delayed
- **No SSL/TLS for email:** Email traffic not encrypted

## Best Practices for Running Reports

1. **Schedule Regular Reports:** Run monthly or quarterly
2. **Compare Over Time:** Track improvements and regressions
3. **Prioritize Fails:** Address critical issues first
4. **Review Warnings:** Plan improvements for warnings
5. **Document Changes:** Keep reports for compliance auditing
6. **Share with Stakeholders:** Use reports for security reviews

## Troubleshooting

### Module Installation Issues
```powershell
# Manual installation
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force
Install-Module Microsoft.Graph.DeviceManagement.Enrollment -Scope CurrentUser -Force
```

### Permission Issues
Ensure you have at least:
- Global Reader role, or
- Intune Administrator role, or
- Custom role with read permissions to all Intune configurations

### Connection Issues
```powershell
# Disconnect and reconnect
Disconnect-MgGraph
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All"
```

## New Test Categories Details

### Conditional Access Policies
Analyzes each CA policy for:
- MFA requirements
- Device compliance requirements
- Approved app requirements
- Platform targeting
- Location-based policies
- Sign-in risk levels
- Session controls
- User and group exclusions

### App Protection Policies (MAM)
Deep analysis of iOS, Android, and Windows policies:
- PIN requirements and strength
- Data backup controls
- Save As restrictions
- Managed browser enforcement
- Screen capture blocking
- Encryption settings
- Organizational credential requirements
- Print blocking

### Windows Autopilot Profiles
Validates deployment profiles for:
- Device naming templates
- OOBE (Out-of-Box Experience) settings
- User account type (standard vs admin)
- Enrollment Status Page configuration
- Escape link blocking
- Privacy settings hiding
- Hybrid Azure AD join configuration

### Assignment Filters
Inventory of device filters with:
- Platform targeting
- Filter rules and logic
- Usage recommendations

### PowerShell Scripts & Proactive Remediations
Analysis of:
- PowerShell scripts (execution context, signature checks)
- Proactive remediation packages (detection + remediation)
- Run as account (System vs User)
- Script security settings

### RBAC Configuration
Review of:
- Built-in vs custom roles
- Permission definitions
- Role assignments
- Delegation strategy

### Enrollment Tokens & Certificates
**Critical expiration monitoring** for:
- **Apple Push Notification Certificate** (critical - expires yearly)
- **VPP Tokens** (Volume Purchase Program)
- **DEP Tokens** (Device Enrollment Program)
- **Android Enterprise Binding** status

**Expiration Alerts:**
- 🔴 **FAIL** - Less than 30 days (immediate action required)
- ⚠️ **WARNING** - 30-60 days (plan renewal)
- ✅ **PASS** - More than 60 days

## Roadmap

Planned enhancements:
- [ ] JSON export for automation
- [ ] Comparison between tenants
- [ ] Historical trend analysis
- [ ] Email notification support for token expirations
- [ ] PowerBI dashboard integration
- [ ] Compliance score calculation
- [ ] Remediation script generation
- [ ] Custom best practice frameworks
- [ ] Scheduled task automation
- [ ] Teams/Slack webhook integration

## Support

For issues or questions:
1. Check the generated report for specific error messages
2. Verify you have the required permissions
3. Ensure modules are up to date: `Update-Module Microsoft.Graph.*`

## Version History

### v1.0 - October 2025
- Initial release with deep configuration analysis
- Microsoft best practices framework
- Enhanced HTML reporting
- Support for Windows, iOS, and Android policies

## License

See LICENSE file in repository root.

## Author

Bareminimum Solutions
© 2025 All rights reserved
