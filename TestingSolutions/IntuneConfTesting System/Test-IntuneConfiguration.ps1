<#
.SYNOPSIS
    Tests Microsoft Intune configuration and generates a comprehensive report.

.DESCRIPTION
    This script tests various aspects of Microsoft Intune configuration including:
    - Device Compliance and Configuration Profiles
    - Application management and deployment
    - Endpoint Security policies
    - Enrollment settings
    - Reports and monitoring capabilities

.PARAMETER OutputPath
    Path where the HTML report will be saved. Default is current directory.

.PARAMETER TenantId
    Azure AD Tenant ID (optional - will prompt for authentication)

.EXAMPLE
    .\Test-IntuneConfiguration.ps1 -OutputPath "C:\Reports"

.NOTES
    Author: Bareminimum Solutions
    Date: October 16, 2025
    Requires: Microsoft.Graph PowerShell modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".",
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId
)

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement, Microsoft.Graph.DeviceManagement.Enrollment

# Import required modules
$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.DeviceManagement',
    'Microsoft.Graph.DeviceManagement.Enrollment'
)

Write-Host "Checking required modules..." -ForegroundColor Cyan
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $module -Force
}

# Connect to Microsoft Graph
function Connect-ToGraph {
    param(
        [string]$TenantId
    )
    
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    
    $scopes = @(
        "DeviceManagementConfiguration.Read.All",
        "DeviceManagementApps.Read.All",
        "DeviceManagementManagedDevices.Read.All",
        "DeviceManagementServiceConfig.Read.All",
        "Policy.Read.All"
    )
    
    if ($TenantId) {
        Connect-MgGraph -Scopes $scopes -TenantId $TenantId
    }
    else {
        Connect-MgGraph -Scopes $scopes
    }
    
    $context = Get-MgContext
    Write-Host "Connected to tenant: $($context.TenantId)" -ForegroundColor Green
}

# Test results object
$testResults = @{
    TestDate              = Get-Date
    TenantInfo            = @{}
    CompliancePolicies    = @{}
    ConfigurationProfiles = @{}
    Applications          = @{}
    EndpointSecurity      = @{}
    EnrollmentSettings    = @{}
    Monitoring            = @{}
    BestPractices         = @{}
    ConditionalAccess     = @{}
    AppProtection         = @{}
    AutopilotProfiles     = @{}
    DeviceFilters         = @{}
    Scripts               = @{}
    RBAC                  = @{}
    EnrollmentTokens      = @{}
    Summary               = @{
        TotalTests   = 0
        PassedTests  = 0
        FailedTests  = 0
        WarningTests = 0
    }
}

# Helper function to add test result
function Add-TestResult {
    param(
        [string]$Category,
        [string]$TestName,
        [string]$Status,  # Pass, Fail, Warning
        [string]$Details,
        [object]$Data = $null
    )
    
    $result = @{
        TestName  = $TestName
        Status    = $Status
        Details   = $Details
        Data      = $Data
        Timestamp = Get-Date
    }
    
    if (-not $testResults[$Category].Tests) {
        $testResults[$Category].Tests = @()
    }
    
    $testResults[$Category].Tests += $result
    $testResults.Summary.TotalTests++
    
    switch ($Status) {
        "Pass" { $testResults.Summary.PassedTests++ }
        "Fail" { $testResults.Summary.FailedTests++ }
        "Warning" { $testResults.Summary.WarningTests++ }
    }
}

# Test 1: Device Compliance Policies
function Test-CompliancePolicies {
    Write-Host "`nTesting Device Compliance Policies..." -ForegroundColor Cyan
    
    try {
        $compliancePolicies = Get-MgDeviceManagementDeviceCompliancePolicy -All
        
        if ($compliancePolicies.Count -eq 0) {
            Add-TestResult -Category "CompliancePolicies" -TestName "Compliance Policies Exist" `
                -Status "Warning" -Details "No compliance policies found" -Data $null
        }
        else {
            Add-TestResult -Category "CompliancePolicies" -TestName "Compliance Policies Exist" `
                -Status "Pass" -Details "$($compliancePolicies.Count) compliance policies found" `
                -Data $compliancePolicies
            
            # Deep dive into each policy
            foreach ($policy in $compliancePolicies) {
                $policyDetails = $policy.AdditionalProperties
                $issues = @()
                $strengths = @()
                
                # Check assignment
                try {
                    $assignments = Get-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $policy.Id
                    
                    if ($assignments.Count -eq 0) {
                        $issues += "Not assigned to any groups"
                    }
                    else {
                        $strengths += "Assigned to $($assignments.Count) group(s)"
                    }
                }
                catch {
                    $issues += "Unable to check assignments"
                }
                
                # Analyze Windows 10 Compliance Settings
                if ($policy.AdditionalProperties.'@odata.type' -like '*windows10CompliancePolicy*') {
                    # Password settings
                    if ($policyDetails.passwordRequired -eq $true) {
                        $strengths += "Password required: Yes"
                        
                        if ($policyDetails.passwordMinimumLength -ge 8) {
                            $strengths += "Password minimum length: $($policyDetails.passwordMinimumLength) (Good)"
                        }
                        elseif ($policyDetails.passwordMinimumLength) {
                            $issues += "Password minimum length: $($policyDetails.passwordMinimumLength) (Recommended: 8+)"
                        }
                        
                        if ($policyDetails.passwordRequireToUnlockFromIdle -eq $true) {
                            $strengths += "Password required after idle: Yes"
                        }
                    }
                    else {
                        $issues += "Password not required (Best practice: Enable)"
                    }
                    
                    # BitLocker
                    if ($policyDetails.bitLockerEnabled -eq $true) {
                        $strengths += "BitLocker required: Yes"
                    }
                    else {
                        $issues += "BitLocker not required (Best practice: Enable for data protection)"
                    }
                    
                    # Secure Boot
                    if ($policyDetails.secureBootEnabled -eq $true) {
                        $strengths += "Secure Boot required: Yes"
                    }
                    else {
                        $issues += "Secure Boot not required (Best practice: Enable)"
                    }
                    
                    # TPM
                    if ($policyDetails.tpmRequired -eq $true) {
                        $strengths += "TPM required: Yes"
                    }
                    else {
                        $issues += "TPM not required (Best practice: Enable)"
                    }
                    
                    # OS Version
                    if ($policyDetails.osMinimumVersion) {
                        $strengths += "Minimum OS version enforced: $($policyDetails.osMinimumVersion)"
                    }
                    else {
                        $issues += "No minimum OS version enforced (Best practice: Require current versions)"
                    }
                    
                    # Antivirus
                    if ($policyDetails.antivirusRequired -eq $true) {
                        $strengths += "Antivirus required: Yes"
                    }
                    else {
                        $issues += "Antivirus not required (Best practice: Enable)"
                    }
                    
                    if ($policyDetails.antiSpywareRequired -eq $true) {
                        $strengths += "Anti-spyware required: Yes"
                    }
                    else {
                        $issues += "Anti-spyware not required (Best practice: Enable)"
                    }
                    
                    # Firewall
                    if ($policyDetails.firewallEnabled -eq $true) {
                        $strengths += "Firewall required: Yes"
                    }
                    else {
                        $issues += "Firewall not required (Best practice: Enable)"
                    }
                    
                    # Device Threat Protection
                    if ($policyDetails.deviceThreatProtectionEnabled -eq $true) {
                        $strengths += "Device Threat Protection enabled: Yes"
                        
                        if ($policyDetails.deviceThreatProtectionRequiredSecurityLevel) {
                            $strengths += "Required security level: $($policyDetails.deviceThreatProtectionRequiredSecurityLevel)"
                        }
                    }
                    else {
                        $issues += "Device Threat Protection not enabled (Consider enabling with Microsoft Defender for Endpoint)"
                    }
                    
                    # Code Integrity
                    if ($policyDetails.codeIntegrityEnabled -eq $true) {
                        $strengths += "Code Integrity required: Yes"
                    }
                }
                
                # Analyze iOS Compliance Settings
                if ($policy.AdditionalProperties.'@odata.type' -like '*iosCompliancePolicy*') {
                    # Passcode settings
                    if ($policyDetails.passcodeRequired -eq $true) {
                        $strengths += "Passcode required: Yes"
                        
                        if ($policyDetails.passcodeMinimumLength -ge 6) {
                            $strengths += "Passcode minimum length: $($policyDetails.passcodeMinimumLength) (Good)"
                        }
                        elseif ($policyDetails.passcodeMinimumLength) {
                            $issues += "Passcode minimum length: $($policyDetails.passcodeMinimumLength) (Recommended: 6+)"
                        }
                    }
                    else {
                        $issues += "Passcode not required (Best practice: Enable)"
                    }
                    
                    # OS Version
                    if ($policyDetails.osMinimumVersion) {
                        $strengths += "Minimum OS version enforced: $($policyDetails.osMinimumVersion)"
                    }
                    else {
                        $issues += "No minimum OS version enforced (Best practice: Require iOS 15+)"
                    }
                    
                    # Jailbreak detection
                    if ($policyDetails.securityBlockJailbrokenDevices -eq $true) {
                        $strengths += "Jailbroken devices blocked: Yes"
                    }
                    else {
                        $issues += "Jailbroken devices not blocked (Best practice: Enable)"
                    }
                }
                
                # Analyze Android Compliance Settings
                if ($policy.AdditionalProperties.'@odata.type' -like '*androidCompliancePolicy*' -or 
                    $policy.AdditionalProperties.'@odata.type' -like '*androidWorkProfileCompliancePolicy*') {
                    
                    # Password settings
                    if ($policyDetails.passwordRequired -eq $true) {
                        $strengths += "Password required: Yes"
                        
                        if ($policyDetails.passwordMinimumLength -ge 6) {
                            $strengths += "Password minimum length: $($policyDetails.passwordMinimumLength) (Good)"
                        }
                        elseif ($policyDetails.passwordMinimumLength) {
                            $issues += "Password minimum length: $($policyDetails.passwordMinimumLength) (Recommended: 6+)"
                        }
                    }
                    else {
                        $issues += "Password not required (Best practice: Enable)"
                    }
                    
                    # Encryption
                    if ($policyDetails.storageRequireEncryption -eq $true) {
                        $strengths += "Device encryption required: Yes"
                    }
                    else {
                        $issues += "Device encryption not required (Best practice: Enable)"
                    }
                    
                    # OS Version
                    if ($policyDetails.osMinimumVersion) {
                        $strengths += "Minimum OS version enforced: $($policyDetails.osMinimumVersion)"
                    }
                    else {
                        $issues += "No minimum OS version enforced (Best practice: Require Android 10+)"
                    }
                    
                    # Root detection
                    if ($policyDetails.securityBlockJailbrokenDevices -eq $true) {
                        $strengths += "Rooted devices blocked: Yes"
                    }
                    else {
                        $issues += "Rooted devices not blocked (Best practice: Enable)"
                    }
                }
                
                # Determine overall status
                $status = "Pass"
                $detailText = ""
                
                if ($issues.Count -gt 0) {
                    if ($issues.Count -gt 3) {
                        $status = "Fail"
                        $detailText = "Multiple best practice issues found"
                    }
                    else {
                        $status = "Warning"
                        $detailText = "Some best practice recommendations"
                    }
                }
                
                if ($strengths.Count -gt 0) {
                    $detailText += " | Strengths: $($strengths.Count)"
                }
                
                $detailText += "`n✓ Strengths: " + ($strengths -join "; ")
                if ($issues.Count -gt 0) {
                    $detailText += "`n⚠ Issues: " + ($issues -join "; ")
                }
                
                Add-TestResult -Category "CompliancePolicies" `
                    -TestName "Deep Analysis: $($policy.DisplayName)" `
                    -Status $status `
                    -Details $detailText `
                    -Data @{Policy = $policy; Strengths = $strengths; Issues = $issues }
            }
        }
        
        $testResults.CompliancePolicies.Summary = @{
            TotalPolicies = $compliancePolicies.Count
            Platforms     = ($compliancePolicies | Group-Object -Property '@odata.type' | Select-Object Name, Count)
        }
        
    }
    catch {
        Add-TestResult -Category "CompliancePolicies" -TestName "Compliance Policies Access" `
            -Status "Fail" -Details "Error accessing compliance policies: $($_.Exception.Message)"
    }
}

# Test 2: Configuration Profiles
function Test-ConfigurationProfiles {
    Write-Host "`nTesting Configuration Profiles..." -ForegroundColor Cyan
    
    try {
        $configProfiles = Get-MgDeviceManagementDeviceConfiguration -All
        
        if ($configProfiles.Count -eq 0) {
            Add-TestResult -Category "ConfigurationProfiles" -TestName "Configuration Profiles Exist" `
                -Status "Warning" -Details "No configuration profiles found"
        }
        else {
            Add-TestResult -Category "ConfigurationProfiles" -TestName "Configuration Profiles Exist" `
                -Status "Pass" -Details "$($configProfiles.Count) configuration profiles found" `
                -Data $configProfiles
            
            # Deep dive into each profile
            foreach ($profile in $configProfiles) {
                $profileDetails = $profile.AdditionalProperties
                $issues = @()
                $strengths = @()
                $recommendations = @()
                
                # Check assignment
                try {
                    $assignments = Get-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $profile.Id
                    
                    if ($assignments.Count -eq 0) {
                        $issues += "Not assigned to any groups"
                    }
                    else {
                        $strengths += "Assigned to $($assignments.Count) group(s)"
                    }
                }
                catch {
                    $issues += "Unable to check assignments"
                }
                
                # Analyze Windows 10 Device Restriction Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*windows10GeneralConfiguration*') {
                    
                    # Password policies
                    if ($profileDetails.passwordRequired -eq $true) {
                        $strengths += "Password enforcement enabled"
                        
                        if ($profileDetails.passwordMinimumLength -ge 8) {
                            $strengths += "Password length: $($profileDetails.passwordMinimumLength) characters (Good)"
                        }
                        
                        if ($profileDetails.passwordExpirationDays) {
                            $strengths += "Password expiration: $($profileDetails.passwordExpirationDays) days"
                        }
                    }
                    
                    # Microsoft Defender settings
                    if ($profileDetails.defenderBlockEndUserAccess -eq $false) {
                        $strengths += "Users can access Defender interface"
                    }
                    
                    if ($profileDetails.defenderRequireRealTimeMonitoring -eq $true) {
                        $strengths += "Real-time monitoring required"
                    }
                    else {
                        $issues += "Real-time monitoring not enforced (Best practice: Enable)"
                    }
                    
                    if ($profileDetails.defenderRequireCloudProtection -eq $true) {
                        $strengths += "Cloud-delivered protection enabled"
                    }
                    else {
                        $recommendations += "Consider enabling cloud-delivered protection"
                    }
                    
                    # SmartScreen settings
                    if ($profileDetails.smartScreenEnableInShell -eq $true) {
                        $strengths += "SmartScreen for file downloads enabled"
                    }
                    else {
                        $issues += "SmartScreen not enabled (Best practice: Enable)"
                    }
                    
                    if ($profileDetails.smartScreenBlockPromptOverride -eq $true) {
                        $strengths += "SmartScreen warnings cannot be bypassed"
                    }
                    
                    # Windows Update settings
                    if ($profileDetails.updateNotificationLevel) {
                        $strengths += "Update notifications configured: $($profileDetails.updateNotificationLevel)"
                    }
                    
                    # Privacy settings
                    if ($profileDetails.privacyBlockInputPersonalization -eq $true) {
                        $strengths += "Input personalization blocked for privacy"
                    }
                    
                    # Cloud and storage
                    if ($profileDetails.storageBlockRemovableStorage -eq $true) {
                        $strengths += "Removable storage blocked (high security)"
                    }
                }
                
                # Analyze Windows Update for Business Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*windowsUpdateForBusinessConfiguration*') {
                    
                    if ($profileDetails.automaticUpdateMode) {
                        $strengths += "Automatic updates configured: $($profileDetails.automaticUpdateMode)"
                        
                        if ($profileDetails.automaticUpdateMode -eq 'notifyDownload') {
                            $recommendations += "Consider 'autoInstallAtMaintenanceTime' for better security"
                        }
                    }
                    else {
                        $issues += "Automatic update mode not configured"
                    }
                    
                    if ($profileDetails.qualityUpdatesDeferralPeriodInDays -ne $null) {
                        if ($profileDetails.qualityUpdatesDeferralPeriodInDays -le 7) {
                            $strengths += "Quality updates deferred by $($profileDetails.qualityUpdatesDeferralPeriodInDays) days (Good)"
                        }
                        else {
                            $recommendations += "Quality updates deferred by $($profileDetails.qualityUpdatesDeferralPeriodInDays) days (Consider reducing to 0-7 days)"
                        }
                    }
                    
                    if ($profileDetails.featureUpdatesDeferralPeriodInDays -ne $null) {
                        $strengths += "Feature updates deferred by $($profileDetails.featureUpdatesDeferralPeriodInDays) days"
                    }
                    
                    if ($profileDetails.microsoftUpdateServiceAllowed -eq $true) {
                        $strengths += "Microsoft Update Service enabled (Office updates)"
                    }
                    
                    if ($profileDetails.driversExcluded -eq $true) {
                        $recommendations += "Drivers excluded from updates - ensure you have alternative driver management"
                    }
                }
                
                # Analyze iOS Device Restriction Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*iosGeneralDeviceConfiguration*') {
                    
                    # Passcode settings
                    if ($profileDetails.passcodeRequired -eq $true) {
                        $strengths += "Passcode required"
                        
                        if ($profileDetails.passcodeMinimumLength -ge 6) {
                            $strengths += "Passcode length: $($profileDetails.passcodeMinimumLength) (Good)"
                        }
                    }
                    else {
                        $issues += "Passcode not required (Best practice: Enable)"
                    }
                    
                    # Security features
                    if ($profileDetails.appStoreBlockAutomaticDownloads -eq $false) {
                        $recommendations += "Consider blocking automatic app downloads for better control"
                    }
                    
                    if ($profileDetails.safariBlockAutofill -eq $true) {
                        $strengths += "Safari autofill blocked (good for security)"
                    }
                    
                    if ($profileDetails.cameraBlocked -eq $true) {
                        $strengths += "Camera blocked (high security environment)"
                    }
                    
                    if ($profileDetails.iCloudBlockBackup -eq $true) {
                        $strengths += "iCloud backup blocked (data residency control)"
                    }
                }
                
                # Analyze Android Device Restriction Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*androidGeneralDeviceConfiguration*' -or
                    $profile.AdditionalProperties.'@odata.type' -like '*androidWorkProfileGeneralDeviceConfiguration*') {
                    
                    # Password settings
                    if ($profileDetails.passwordRequired -eq $true) {
                        $strengths += "Password required"
                    }
                    else {
                        $issues += "Password not required (Best practice: Enable)"
                    }
                    
                    # Security features
                    if ($profileDetails.securityRequireVerifyApps -eq $true) {
                        $strengths += "App verification required (Play Protect)"
                    }
                    else {
                        $issues += "App verification not required (Best practice: Enable Play Protect)"
                    }
                    
                    if ($profileDetails.storageBlockGoogleBackup -eq $true) {
                        $strengths += "Google backup blocked (data control)"
                    }
                    
                    if ($profileDetails.cameraBlocked -eq $true) {
                        $strengths += "Camera blocked (high security)"
                    }
                }
                
                # Analyze Email Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*emailProfile*') {
                    $strengths += "Email profile configured for native mail apps"
                    
                    if ($profileDetails.requireSsl -eq $true) {
                        $strengths += "SSL/TLS required for email"
                    }
                    else {
                        $issues += "SSL/TLS not required (Best practice: Enable encryption)"
                    }
                    
                    if ($profileDetails.requireSmime -eq $true) {
                        $strengths += "S/MIME encryption enabled (excellent security)"
                    }
                }
                
                # Analyze WiFi Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*wifi*') {
                    $strengths += "WiFi profile configured"
                    
                    if ($profileDetails.wiFiSecurityType -eq 'wpa2Enterprise' -or 
                        $profileDetails.wiFiSecurityType -eq 'wpa3Enterprise') {
                        $strengths += "Enterprise WiFi security: $($profileDetails.wiFiSecurityType) (Excellent)"
                    }
                    elseif ($profileDetails.wiFiSecurityType -eq 'open') {
                        $issues += "Open WiFi network (Security risk - use WPA2/WPA3)"
                    }
                    
                    if ($profileDetails.connectAutomatically -eq $true) {
                        $strengths += "Auto-connect enabled for corporate WiFi"
                    }
                }
                
                # Analyze VPN Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*vpn*') {
                    $strengths += "VPN profile configured"
                    
                    if ($profileDetails.connectionType) {
                        $strengths += "VPN type: $($profileDetails.connectionType)"
                    }
                    
                    if ($profileDetails.enableSplitTunneling -eq $false) {
                        $strengths += "Split tunneling disabled (all traffic through VPN)"
                    }
                    else {
                        $recommendations += "Split tunneling enabled - ensure this aligns with security policy"
                    }
                }
                
                # Analyze Endpoint Protection Profiles
                if ($profile.AdditionalProperties.'@odata.type' -like '*windows10EndpointProtectionConfiguration*') {
                    
                    # BitLocker settings
                    if ($profileDetails.bitLockerSystemDrivePolicy) {
                        $strengths += "BitLocker system drive policy configured"
                    }
                    else {
                        $recommendations += "Consider configuring BitLocker for system drive"
                    }
                    
                    # Firewall settings
                    if ($profileDetails.firewallBlockStatefulFTP -eq $true) {
                        $strengths += "Stateful FTP blocked in firewall"
                    }
                    
                    # Application Guard
                    if ($profileDetails.applicationGuardEnabled -eq $true) {
                        $strengths += "Windows Defender Application Guard enabled (Excellent)"
                    }
                    
                    # Credential Guard
                    if ($profileDetails.deviceGuardEnableVirtualizationBasedSecurity -eq $true) {
                        $strengths += "Virtualization-based security enabled (Excellent)"
                    }
                }
                
                # Determine overall status
                $status = "Pass"
                $detailText = ""
                
                if ($issues.Count -gt 0) {
                    if ($issues.Count -ge 3) {
                        $status = "Fail"
                        $detailText = "Critical configuration issues found"
                    }
                    else {
                        $status = "Warning"
                        $detailText = "Configuration improvements recommended"
                    }
                }
                elseif ($recommendations.Count -gt 2) {
                    $status = "Warning"
                    $detailText = "Good configuration with optimization opportunities"
                }
                
                # Build detail output
                if ($strengths.Count -gt 0) {
                    $detailText += "`n✓ Strengths ($($strengths.Count)): " + ($strengths -join "; ")
                }
                if ($issues.Count -gt 0) {
                    $detailText += "`n❌ Issues ($($issues.Count)): " + ($issues -join "; ")
                }
                if ($recommendations.Count -gt 0) {
                    $detailText += "`n💡 Recommendations ($($recommendations.Count)): " + ($recommendations -join "; ")
                }
                
                Add-TestResult -Category "ConfigurationProfiles" `
                    -TestName "Deep Analysis: $($profile.DisplayName)" `
                    -Status $status `
                    -Details $detailText `
                    -Data @{Profile = $profile; Strengths = $strengths; Issues = $issues; Recommendations = $recommendations }
            }
        }
        
        $testResults.ConfigurationProfiles.Summary = @{
            TotalProfiles = $configProfiles.Count
            Types         = ($configProfiles | Group-Object -Property '@odata.type' | Select-Object Name, Count)
        }
        
    }
    catch {
        Add-TestResult -Category "ConfigurationProfiles" -TestName "Configuration Profiles Access" `
            -Status "Fail" -Details "Error accessing configuration profiles: $($_.Exception.Message)"
    }
}

# Test 3: Application Management
function Test-Applications {
    Write-Host "`nTesting Application Management..." -ForegroundColor Cyan
    
    try {
        $apps = Get-MgDeviceAppManagementMobileApp -All
        
        if ($apps.Count -eq 0) {
            Add-TestResult -Category "Applications" -TestName "Applications Exist" `
                -Status "Warning" -Details "No applications found"
        }
        else {
            Add-TestResult -Category "Applications" -TestName "Applications Exist" `
                -Status "Pass" -Details "$($apps.Count) applications found" `
                -Data $apps
            
            # Check app assignments
            $assignedApps = 0
            $unassignedApps = 0
            
            foreach ($app in $apps) {
                try {
                    $assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id
                    
                    if ($assignments.Count -eq 0) {
                        $unassignedApps++
                    }
                    else {
                        $assignedApps++
                    }
                }
                catch {
                    # Some apps might not support assignment queries
                }
            }
            
            if ($unassignedApps -gt 0) {
                Add-TestResult -Category "Applications" -TestName "Application Assignments" `
                    -Status "Warning" `
                    -Details "$unassignedApps out of $($apps.Count) apps are not assigned"
            }
            else {
                Add-TestResult -Category "Applications" -TestName "Application Assignments" `
                    -Status "Pass" `
                    -Details "All applications are assigned"
            }
        }
        
        $testResults.Applications.Summary = @{
            TotalApps = $apps.Count
            AppTypes  = ($apps | Group-Object -Property '@odata.type' | Select-Object Name, Count)
        }
        
    }
    catch {
        Add-TestResult -Category "Applications" -TestName "Applications Access" `
            -Status "Fail" -Details "Error accessing applications: $($_.Exception.Message)"
    }
}

# Test 4: Endpoint Security Policies
function Test-EndpointSecurity {
    Write-Host "`nTesting Endpoint Security Policies..." -ForegroundColor Cyan
    
    try {
        # Use Graph API directly for endpoint security
        # Test Antivirus policies
        try {
            $antivirusResponse = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents?`$filter=templateId eq '804339ad-1553-4478-a742-138fb5807418'"
            $antivirusPolicies = $antivirusResponse.value
            
            Add-TestResult -Category "EndpointSecurity" -TestName "Antivirus Policies" `
                -Status $(if ($antivirusPolicies.Count -gt 0) { "Pass" } else { "Warning" }) `
                -Details "$($antivirusPolicies.Count) antivirus policies found" `
                -Data $antivirusPolicies
        }
        catch {
            Add-TestResult -Category "EndpointSecurity" -TestName "Antivirus Policies" `
                -Status "Warning" -Details "Unable to access antivirus policies: $($_.Exception.Message)"
        }
        
        # Test Disk Encryption policies (BitLocker)
        try {
            $diskEncryptionResponse = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents?`$filter=templateId eq 'd02f2162-fcac-48db-9b7b-b0a5f76f6c6e'"
            $diskEncryptionPolicies = $diskEncryptionResponse.value
            
            Add-TestResult -Category "EndpointSecurity" -TestName "Disk Encryption Policies" `
                -Status $(if ($diskEncryptionPolicies.Count -gt 0) { "Pass" } else { "Warning" }) `
                -Details "$($diskEncryptionPolicies.Count) disk encryption policies found" `
                -Data $diskEncryptionPolicies
        }
        catch {
            Add-TestResult -Category "EndpointSecurity" -TestName "Disk Encryption Policies" `
                -Status "Warning" -Details "Unable to access disk encryption policies"
        }
        
        # Test Firewall policies
        try {
            $firewallResponse = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents?`$filter=templateId eq '4356d05c-a4ab-4a07-9ece-739f7c792910'"
            $firewallPolicies = $firewallResponse.value
            
            Add-TestResult -Category "EndpointSecurity" -TestName "Firewall Policies" `
                -Status $(if ($firewallPolicies.Count -gt 0) { "Pass" } else { "Warning" }) `
                -Details "$($firewallPolicies.Count) firewall policies found" `
                -Data $firewallPolicies
        }
        catch {
            Add-TestResult -Category "EndpointSecurity" -TestName "Firewall Policies" `
                -Status "Warning" -Details "Unable to access firewall policies"
        }
        
        # Test Attack Surface Reduction policies
        try {
            $asrResponse = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents?`$filter=templateId eq 'c7a4c382-b0c7-4d29-9e6b-3e0c1a8e0c1a'"
            $asrPolicies = $asrResponse.value
            
            Add-TestResult -Category "EndpointSecurity" -TestName "Attack Surface Reduction Policies" `
                -Status $(if ($asrPolicies.Count -gt 0) { "Pass" } else { "Warning" }) `
                -Details "$($asrPolicies.Count) ASR policies found" `
                -Data $asrPolicies
        }
        catch {
            Add-TestResult -Category "EndpointSecurity" -TestName "Attack Surface Reduction Policies" `
                -Status "Warning" -Details "Unable to access ASR policies"
        }
        
        $testResults.EndpointSecurity.Summary = @{
            AntivirusPolicies      = if ($antivirusPolicies) { $antivirusPolicies.Count } else { 0 }
            DiskEncryptionPolicies = if ($diskEncryptionPolicies) { $diskEncryptionPolicies.Count } else { 0 }
            FirewallPolicies       = if ($firewallPolicies) { $firewallPolicies.Count } else { 0 }
            ASRPolicies            = if ($asrPolicies) { $asrPolicies.Count } else { 0 }
        }
        
    }
    catch {
        Add-TestResult -Category "EndpointSecurity" -TestName "Endpoint Security Access" `
            -Status "Fail" -Details "Error accessing endpoint security policies: $($_.Exception.Message)"
    }
}

# Test 5: Enrollment Settings
function Test-EnrollmentSettings {
    Write-Host "`nTesting Enrollment Settings..." -ForegroundColor Cyan
    
    try {
        # Test Enrollment Restrictions
        $enrollmentRestrictions = Get-MgDeviceManagementDeviceEnrollmentConfiguration -All
        
        if ($enrollmentRestrictions.Count -eq 0) {
            Add-TestResult -Category "EnrollmentSettings" -TestName "Enrollment Configurations" `
                -Status "Warning" -Details "No enrollment configurations found"
        }
        else {
            Add-TestResult -Category "EnrollmentSettings" -TestName "Enrollment Configurations" `
                -Status "Pass" -Details "$($enrollmentRestrictions.Count) enrollment configurations found" `
                -Data $enrollmentRestrictions
        }
        
        # Test Autopilot profiles (if accessible)
        try {
            $autopilotProfiles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles"
            
            Add-TestResult -Category "EnrollmentSettings" -TestName "Autopilot Profiles" `
                -Status $(if ($autopilotProfiles.value.Count -gt 0) { "Pass" } else { "Warning" }) `
                -Details "$($autopilotProfiles.value.Count) Autopilot profiles found" `
                -Data $autopilotProfiles.value
                
            $testResults.EnrollmentSettings.AutopilotProfiles = $autopilotProfiles.value.Count
        }
        catch {
            Add-TestResult -Category "EnrollmentSettings" -TestName "Autopilot Profiles" `
                -Status "Warning" -Details "Unable to access Autopilot profiles"
        }
        
        $testResults.EnrollmentSettings.Summary = @{
            EnrollmentConfigs = $enrollmentRestrictions.Count
        }
        
    }
    catch {
        Add-TestResult -Category "EnrollmentSettings" -TestName "Enrollment Settings Access" `
            -Status "Fail" -Details "Error accessing enrollment settings: $($_.Exception.Message)"
    }
}

# Test 6: Microsoft Best Practices
function Test-BestPractices {
    Write-Host "`nTesting Microsoft Best Practices..." -ForegroundColor Cyan
    
    try {
        # Best Practice 1: Multi-Factor Authentication (Conditional Access)
        try {
            $caPolicies = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
            
            $mfaPolicies = $caPolicies.value | Where-Object { $_.grantControls.builtInControls -contains "mfa" }
            
            if ($mfaPolicies.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "MFA Enforcement via Conditional Access" `
                    -Status "Pass" -Details "$($mfaPolicies.Count) Conditional Access policies require MFA" `
                    -Data $mfaPolicies
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "MFA Enforcement via Conditional Access" `
                    -Status "Warning" -Details "No Conditional Access policies requiring MFA found - Microsoft recommends enforcing MFA"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "MFA Enforcement via Conditional Access" `
                -Status "Warning" -Details "Unable to verify MFA policies - requires additional permissions"
        }
        
        # Best Practice 2: Windows Update Rings
        try {
            $updateRings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windowsUpdateForBusinessConfiguration')"
            
            if ($updateRings.value.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Windows Update Management" `
                    -Status "Pass" -Details "$($updateRings.value.Count) Windows Update rings configured" `
                    -Data $updateRings.value
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Windows Update Management" `
                    -Status "Warning" -Details "No Windows Update rings found - Microsoft recommends managing updates via Intune"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Windows Update Management" `
                -Status "Warning" -Details "Unable to verify Windows Update configuration"
        }
        
        # Best Practice 3: Minimum OS Version Compliance
        try {
            $compliancePolicies = Get-MgDeviceManagementDeviceCompliancePolicy -All
            $osVersionPolicies = $compliancePolicies | Where-Object { 
                $_.AdditionalProperties.ContainsKey('osMinimumVersion') -or 
                $_.AdditionalProperties.ContainsKey('osMinimumBuildVersion')
            }
            
            if ($osVersionPolicies.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Minimum OS Version Enforcement" `
                    -Status "Pass" -Details "$($osVersionPolicies.Count) policies enforce minimum OS versions"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Minimum OS Version Enforcement" `
                    -Status "Warning" -Details "No minimum OS version requirements found - Microsoft recommends requiring current OS versions"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Minimum OS Version Enforcement" `
                -Status "Warning" -Details "Unable to verify OS version policies"
        }
        
        # Best Practice 4: Disk Encryption (BitLocker/FileVault)
        try {
            $encryptionPolicies = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents?`$filter=templateId eq 'd02f2162-fcac-48db-9b7b-b0a5f76f6c6e' or templateId eq 'a239407c-698d-4ef8-b314-e3ae409204b8'"
            
            if ($encryptionPolicies.value.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Disk Encryption Enforcement" `
                    -Status "Pass" -Details "$($encryptionPolicies.value.Count) disk encryption policies configured"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Disk Encryption Enforcement" `
                    -Status "Fail" -Details "No disk encryption policies found - Microsoft requires encryption for sensitive data protection"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Disk Encryption Enforcement" `
                -Status "Warning" -Details "Unable to verify disk encryption policies"
        }
        
        # Best Practice 5: Microsoft Defender Antivirus
        try {
            $defenderPolicies = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents?`$filter=templateId eq '804339ad-1553-4478-a742-138fb5807418'"
            
            if ($defenderPolicies.value.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Microsoft Defender Antivirus Configuration" `
                    -Status "Pass" -Details "$($defenderPolicies.value.Count) Defender antivirus policies configured"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Microsoft Defender Antivirus Configuration" `
                    -Status "Fail" -Details "No Defender antivirus policies found - Microsoft requires antivirus protection"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Microsoft Defender Antivirus Configuration" `
                -Status "Warning" -Details "Unable to verify Defender policies"
        }
        
        # Best Practice 6: Password Complexity Requirements
        try {
            $passwordPolicies = Get-MgDeviceManagementDeviceCompliancePolicy -All | Where-Object {
                $_.AdditionalProperties.ContainsKey('passwordRequired') -and 
                $_.AdditionalProperties['passwordRequired'] -eq $true
            }
            
            if ($passwordPolicies.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Password Requirements" `
                    -Status "Pass" -Details "$($passwordPolicies.Count) policies enforce password requirements"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Password Requirements" `
                    -Status "Warning" -Details "No password requirement policies found - Microsoft recommends enforcing strong passwords"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Password Requirements" `
                -Status "Warning" -Details "Unable to verify password policies"
        }
        
        # Best Practice 7: Application Protection Policies (MAM)
        try {
            $mamPolicies = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/managedAppPolicies"
            
            if ($mamPolicies.value.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Mobile Application Management (MAM)" `
                    -Status "Pass" -Details "$($mamPolicies.value.Count) app protection policies configured"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Mobile Application Management (MAM)" `
                    -Status "Warning" -Details "No app protection policies found - Microsoft recommends MAM for mobile devices"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Mobile Application Management (MAM)" `
                -Status "Warning" -Details "Unable to verify MAM policies"
        }
        
        # Best Practice 8: Device Naming Convention
        try {
            $enrollmentProfiles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles"
            
            $namedProfiles = $enrollmentProfiles.value | Where-Object { 
                $_.deviceNameTemplate -and $_.deviceNameTemplate -ne ""
            }
            
            if ($namedProfiles.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Device Naming Convention (Autopilot)" `
                    -Status "Pass" -Details "$($namedProfiles.Count) Autopilot profiles use naming templates"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Device Naming Convention (Autopilot)" `
                    -Status "Warning" -Details "No device naming templates configured - Microsoft recommends standardized naming"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Device Naming Convention (Autopilot)" `
                -Status "Warning" -Details "Unable to verify device naming configuration"
        }
        
        # Best Practice 9: Security Baseline Profiles
        try {
            $securityBaselines = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/templates?`$filter=isof('microsoft.graph.securityBaselineTemplate')"
            
            if ($securityBaselines.value.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Security Baseline Implementation" `
                    -Status "Pass" -Details "Security baseline templates available for deployment"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Security Baseline Implementation" `
                    -Status "Warning" -Details "Consider implementing Microsoft security baselines"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Security Baseline Implementation" `
                -Status "Warning" -Details "Unable to verify security baselines"
        }
        
        # Best Practice 10: Compliance Grace Period
        try {
            $compliancePolicies = Get-MgDeviceManagementDeviceCompliancePolicy -All
            
            $policiesWithGrace = $compliancePolicies | Where-Object {
                $_.ScheduledActionsForRule -and $_.ScheduledActionsForRule.Count -gt 0
            }
            
            if ($policiesWithGrace.Count -gt 0) {
                Add-TestResult -Category "BestPractices" -TestName "Compliance Grace Period Configuration" `
                    -Status "Pass" -Details "$($policiesWithGrace.Count) policies have scheduled actions configured"
            }
            else {
                Add-TestResult -Category "BestPractices" -TestName "Compliance Grace Period Configuration" `
                    -Status "Warning" -Details "Consider configuring compliance grace periods and actions"
            }
        }
        catch {
            Add-TestResult -Category "BestPractices" -TestName "Compliance Grace Period Configuration" `
                -Status "Warning" -Details "Unable to verify grace period configuration"
        }
        
        $testResults.BestPractices.Summary = @{
            Note = "Tests based on Microsoft Intune Best Practices and Security Recommendations"
        }
        
    }
    catch {
        Add-TestResult -Category "BestPractices" -TestName "Best Practices Assessment" `
            -Status "Fail" -Details "Error during best practices assessment: $($_.Exception.Message)"
    }
}

# Test 7: Reports and Monitoring
function Test-Monitoring {
    Write-Host "`nTesting Reports and Monitoring..." -ForegroundColor Cyan
    
    try {
        # Test managed devices visibility
        $managedDevices = Get-MgDeviceManagementManagedDevice -Top 10
        
        if ($managedDevices.Count -eq 0) {
            Add-TestResult -Category "Monitoring" -TestName "Managed Devices Visibility" `
                -Status "Warning" -Details "No managed devices found or unable to access"
        }
        else {
            Add-TestResult -Category "Monitoring" -TestName "Managed Devices Visibility" `
                -Status "Pass" -Details "Successfully accessed managed devices data" `
                -Data $managedDevices
        }
        
        # Test compliance status
        try {
            $complianceStatus = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=id,deviceName,complianceState&`$top=10"
            
            Add-TestResult -Category "Monitoring" -TestName "Compliance Status Access" `
                -Status "Pass" -Details "Successfully accessed compliance status data"
                
        }
        catch {
            Add-TestResult -Category "Monitoring" -TestName "Compliance Status Access" `
                -Status "Warning" -Details "Limited access to compliance status data"
        }
        
        # Test device health monitoring
        try {
            $deviceHealthScripts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
            
            Add-TestResult -Category "Monitoring" -TestName "Device Health Scripts" `
                -Status $(if ($deviceHealthScripts.value.Count -gt 0) { "Pass" } else { "Warning" }) `
                -Details "$($deviceHealthScripts.value.Count) health monitoring scripts found"
                
            $testResults.Monitoring.HealthScripts = $deviceHealthScripts.value.Count
        }
        catch {
            Add-TestResult -Category "Monitoring" -TestName "Device Health Scripts" `
                -Status "Warning" -Details "Unable to access health monitoring scripts"
        }
        
        $testResults.Monitoring.Summary = @{
            ManagedDevicesAccessible = $managedDevices.Count -gt 0
        }
        
    }
    catch {
        Add-TestResult -Category "Monitoring" -TestName "Monitoring Access" `
            -Status "Fail" -Details "Error accessing monitoring features: $($_.Exception.Message)"
    }
}

# Generate HTML Report
function Generate-HTMLReport {
    param(
        [object]$Results,
        [string]$OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "IntuneConfigReport_$timestamp.html"
    $fullPath = Join-Path -Path $OutputPath -ChildPath $fileName
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Microsoft Intune Configuration Test Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; background-color: white; padding: 30px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #106ebe; margin-top: 30px; border-left: 4px solid #0078d4; padding-left: 10px; }
        .summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 20px 0; }
        .summary-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .summary-card h3 { margin: 0; font-size: 2em; }
        .summary-card p { margin: 10px 0 0 0; font-size: 0.9em; }
        .pass { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); }
        .fail { background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%); }
        .warning { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .test-category { margin: 30px 0; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background-color: #0078d4; color: white; padding: 12px; text-align: left; font-weight: 600; }
        td { padding: 10px 12px; border-bottom: 1px solid #e0e0e0; vertical-align: top; }
        tr:hover { background-color: #f5f5f5; }
        .detail-text { white-space: pre-wrap; font-size: 0.9em; line-height: 1.6; }
        .strength-line { color: #28a745; padding: 2px 0; }
        .issue-line { color: #dc3545; padding: 2px 0; }
        .recommendation-line { color: #007bff; padding: 2px 0; }
        .status-pass { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
        .status-warning { color: #ffc107; font-weight: bold; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; text-align: center; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 0.85em; font-weight: 600; }
        .badge-pass { background-color: #d4edda; color: #155724; }
        .badge-fail { background-color: #f8d7da; color: #721c24; }
        .badge-warning { background-color: #fff3cd; color: #856404; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Microsoft Intune Configuration Test Report</h1>
        <p><strong>Generated:</strong> $($Results.TestDate.ToString('yyyy-MM-dd HH:mm:ss'))</p>
        <p><strong>Tenant ID:</strong> $((Get-MgContext).TenantId)</p>
        
        <div class="summary">
            <div class="summary-card">
                <h3>$($Results.Summary.TotalTests)</h3>
                <p>Total Tests</p>
            </div>
            <div class="summary-card pass">
                <h3>$($Results.Summary.PassedTests)</h3>
                <p>Passed</p>
            </div>
            <div class="summary-card fail">
                <h3>$($Results.Summary.FailedTests)</h3>
                <p>Failed</p>
            </div>
            <div class="summary-card warning">
                <h3>$($Results.Summary.WarningTests)</h3>
                <p>Warnings</p>
            </div>
        </div>
"@

    # Add each category
    $categories = @(
        @{Name = "BestPractices"; Title = "Microsoft Best Practices Assessment" },
        @{Name = "ConditionalAccess"; Title = "Conditional Access Policies (Zero Trust)" },
        @{Name = "CompliancePolicies"; Title = "Device Compliance Policies" },
        @{Name = "ConfigurationProfiles"; Title = "Configuration Profiles" },
        @{Name = "AppProtection"; Title = "App Protection Policies (MAM)" },
        @{Name = "Applications"; Title = "Application Management" },
        @{Name = "EndpointSecurity"; Title = "Endpoint Security Policies" },
        @{Name = "AutopilotProfiles"; Title = "Windows Autopilot Deployment Profiles" },
        @{Name = "EnrollmentSettings"; Title = "Enrollment Settings" },
        @{Name = "DeviceFilters"; Title = "Assignment Filters" },
        @{Name = "Scripts"; Title = "PowerShell Scripts & Proactive Remediations" },
        @{Name = "RBAC"; Title = "Role-Based Access Control" },
        @{Name = "EnrollmentTokens"; Title = "Enrollment Tokens & Certificates" },
        @{Name = "Monitoring"; Title = "Reports and Monitoring" }
    )
    
    foreach ($category in $categories) {
        $tests = $Results[$category.Name].Tests
        
        if ($tests) {
            $html += @"
        <div class="test-category">
            <h2>$($category.Title)</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Status</th>
                        <th>Details</th>
                    </tr>
                </thead>
                <tbody>
"@
            
            foreach ($test in $tests) {
                $statusClass = "status-$($test.Status.ToLower())"
                $badgeClass = "badge-$($test.Status.ToLower())"
                
                # Format details with HTML for better readability
                $formattedDetails = $test.Details
                $formattedDetails = $formattedDetails -replace '✓', '<span style="color: #28a745;">✓</span>'
                $formattedDetails = $formattedDetails -replace '❌', '<span style="color: #dc3545;">❌</span>'
                $formattedDetails = $formattedDetails -replace '💡', '<span style="color: #007bff;">💡</span>'
                $formattedDetails = $formattedDetails -replace '⚠', '<span style="color: #ffc107;">⚠</span>'
                
                $html += @"
                    <tr>
                        <td style="font-weight: 500;">$($test.TestName)</td>
                        <td><span class="badge $badgeClass">$($test.Status)</span></td>
                        <td class="detail-text">$formattedDetails</td>
                    </tr>
"@
            }
            
            $html += @"
                </tbody>
            </table>
        </div>
"@
        }
    }
    
    $html += @"
        <div class="footer">
            <p>Report generated by Bareminimum Solutions - Intune Configuration Testing Tool</p>
            <p>© 2025 All rights reserved</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $fullPath -Encoding UTF8
    Write-Host "`nReport generated: $fullPath" -ForegroundColor Green
    return $fullPath
}

# Test 8: Conditional Access Policies (Detailed)
function Test-ConditionalAccessPolicies {
    Write-Host "`nTesting Conditional Access Policies..." -ForegroundColor Cyan
    
    try {
        $caPolicies = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
        
        if ($caPolicies.value.Count -eq 0) {
            Add-TestResult -Category "ConditionalAccess" -TestName "Conditional Access Policies" `
                -Status "Warning" -Details "No Conditional Access policies found - Microsoft recommends CA for zero trust"
        }
        else {
            Add-TestResult -Category "ConditionalAccess" -TestName "Conditional Access Policies Exist" `
                -Status "Pass" -Details "$($caPolicies.value.Count) Conditional Access policies found"
            
            # Analyze each policy
            foreach ($policy in $caPolicies.value) {
                $issues = @()
                $strengths = @()
                $recommendations = @()
                
                # Check if enabled
                if ($policy.state -eq "enabled") {
                    $strengths += "Policy is enabled"
                }
                elseif ($policy.state -eq "enabledForReportingButNotEnforced") {
                    $recommendations += "Policy is in report-only mode - consider enabling"
                }
                else {
                    $issues += "Policy is disabled"
                }
                
                # Check MFA requirement
                if ($policy.grantControls.builtInControls -contains "mfa") {
                    $strengths += "Requires MFA"
                }
                else {
                    $recommendations += "Does not require MFA"
                }
                
                # Check device compliance requirement
                if ($policy.grantControls.builtInControls -contains "compliantDevice") {
                    $strengths += "Requires compliant device"
                }
                elseif ($policy.grantControls.builtInControls -contains "domainJoinedDevice") {
                    $strengths += "Requires domain-joined device"
                }
                
                # Check Approved Client App requirement
                if ($policy.grantControls.builtInControls -contains "approvedApplication") {
                    $strengths += "Requires approved client app"
                }
                
                # Check app protection policy requirement
                if ($policy.grantControls.builtInControls -contains "compliantApplication") {
                    $strengths += "Requires app protection policy"
                }
                
                # Check what users are included
                if ($policy.conditions.users.includeUsers -contains "All") {
                    $strengths += "Applies to all users"
                }
                elseif ($policy.conditions.users.includeGroups) {
                    $strengths += "Applies to $($policy.conditions.users.includeGroups.Count) group(s)"
                }
                
                # Check for exclusions
                if ($policy.conditions.users.excludeUsers.Count -gt 0) {
                    $recommendations += "$($policy.conditions.users.excludeUsers.Count) users excluded - review periodically"
                }
                if ($policy.conditions.users.excludeGroups.Count -gt 0) {
                    $recommendations += "$($policy.conditions.users.excludeGroups.Count) groups excluded - review periodically"
                }
                
                # Check platform conditions
                if ($policy.conditions.platforms.includePlatforms) {
                    $platforms = $policy.conditions.platforms.includePlatforms -join ", "
                    $strengths += "Targets platforms: $platforms"
                }
                
                # Check location conditions
                if ($policy.conditions.locations.includeLocations) {
                    $strengths += "Location-based policy configured"
                }
                
                # Check sign-in risk
                if ($policy.conditions.signInRiskLevels) {
                    $riskLevels = $policy.conditions.signInRiskLevels -join ", "
                    $strengths += "Sign-in risk levels: $riskLevels"
                }
                
                # Check session controls
                if ($policy.sessionControls.signInFrequency) {
                    $strengths += "Sign-in frequency: $($policy.sessionControls.signInFrequency.value) $($policy.sessionControls.signInFrequency.type)"
                }
                
                if ($policy.sessionControls.applicationEnforcedRestrictions.isEnabled) {
                    $strengths += "Application enforced restrictions enabled"
                }
                
                if ($policy.sessionControls.cloudAppSecurity.isEnabled) {
                    $strengths += "Cloud App Security session control enabled"
                }
                
                # Determine status
                $status = if ($issues.Count -gt 0) { "Warning" } else { "Pass" }
                
                $detailText = ""
                if ($strengths.Count -gt 0) {
                    $detailText += "`n✓ Configuration ($($strengths.Count)): " + ($strengths -join "; ")
                }
                if ($issues.Count -gt 0) {
                    $detailText += "`n❌ Issues ($($issues.Count)): " + ($issues -join "; ")
                }
                if ($recommendations.Count -gt 0) {
                    $detailText += "`n💡 Recommendations ($($recommendations.Count)): " + ($recommendations -join "; ")
                }
                
                Add-TestResult -Category "ConditionalAccess" `
                    -TestName "CA Policy: $($policy.displayName)" `
                    -Status $status `
                    -Details $detailText
            }
        }
        
        $testResults.ConditionalAccess.Summary = @{
            TotalPolicies   = $caPolicies.value.Count
            EnabledPolicies = ($caPolicies.value | Where-Object { $_.state -eq "enabled" }).Count
        }
        
    }
    catch {
        Add-TestResult -Category "ConditionalAccess" -TestName "Conditional Access Access" `
            -Status "Warning" -Details "Unable to access Conditional Access policies (may need additional permissions)"
    }
}

# Test 9: App Protection Policies (MAM)
function Test-AppProtectionPolicies {
    Write-Host "`nTesting App Protection Policies..." -ForegroundColor Cyan
    
    try {
        $mamPolicies = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/managedAppPolicies"
        
        if ($mamPolicies.value.Count -eq 0) {
            Add-TestResult -Category "AppProtection" -TestName "App Protection Policies" `
                -Status "Warning" -Details "No app protection policies found - recommended for BYOD and mobile devices"
        }
        else {
            Add-TestResult -Category "AppProtection" -TestName "App Protection Policies Exist" `
                -Status "Pass" -Details "$($mamPolicies.value.Count) app protection policies found"
            
            # Analyze each policy
            foreach ($policy in $mamPolicies.value) {
                $issues = @()
                $strengths = @()
                $recommendations = @()
                
                # iOS App Protection Policies
                if ($policy.'@odata.type' -eq "#microsoft.graph.iosManagedAppProtection") {
                    
                    if ($policy.dataBackupBlocked -eq $true) {
                        $strengths += "Data backup to iCloud blocked"
                    }
                    else {
                        $recommendations += "Consider blocking data backup for sensitive data"
                    }
                    
                    if ($policy.pinRequired -eq $true) {
                        $strengths += "PIN required for app access"
                        
                        if ($policy.minimumPinLength -ge 4) {
                            $strengths += "PIN length: $($policy.minimumPinLength) digits (Good)"
                        }
                    }
                    else {
                        $issues += "PIN not required (Best practice: Enable)"
                    }
                    
                    if ($policy.managedBrowserToOpenLinksRequired -eq $true) {
                        $strengths += "Managed browser required for links"
                    }
                    
                    if ($policy.saveAsBlocked -eq $true) {
                        $strengths += "Save As blocked (data loss prevention)"
                    }
                    
                    if ($policy.organizationalCredentialsRequired -eq $true) {
                        $strengths += "Organizational credentials required"
                    }
                    
                    if ($policy.printBlocked -eq $true) {
                        $strengths += "Printing blocked (high security)"
                    }
                    
                    if ($policy.appDataEncryptionType -ne "useDeviceLockPin") {
                        $strengths += "App data encryption: $($policy.appDataEncryptionType)"
                    }
                }
                
                # Android App Protection Policies
                if ($policy.'@odata.type' -eq "#microsoft.graph.androidManagedAppProtection") {
                    
                    if ($policy.screenCaptureBlocked -eq $true) {
                        $strengths += "Screen capture blocked"
                    }
                    else {
                        $recommendations += "Consider blocking screen capture"
                    }
                    
                    if ($policy.pinRequired -eq $true) {
                        $strengths += "PIN required for app access"
                        
                        if ($policy.minimumPinLength -ge 4) {
                            $strengths += "PIN length: $($policy.minimumPinLength) digits (Good)"
                        }
                    }
                    else {
                        $issues += "PIN not required (Best practice: Enable)"
                    }
                    
                    if ($policy.disableAppPinIfDevicePinIsSet -eq $false) {
                        $strengths += "App PIN required even with device PIN"
                    }
                    
                    if ($policy.encryptAppData -eq $true) {
                        $strengths += "App data encryption enabled"
                    }
                    else {
                        $issues += "App data encryption not enabled (Best practice: Enable)"
                    }
                }
                
                # Windows App Protection Policies
                if ($policy.'@odata.type' -eq "#microsoft.graph.windowsManagedAppProtection") {
                    
                    if ($policy.printBlocked -eq $true) {
                        $strengths += "Printing blocked"
                    }
                    
                    if ($policy.allowedInboundDataTransferSources) {
                        $strengths += "Inbound data transfer restricted"
                    }
                }
                
                # Determine status
                $status = "Pass"
                if ($issues.Count -gt 0) {
                    $status = if ($issues.Count -ge 2) { "Fail" } else { "Warning" }
                }
                
                $detailText = ""
                if ($strengths.Count -gt 0) {
                    $detailText += "`n✓ Strengths ($($strengths.Count)): " + ($strengths -join "; ")
                }
                if ($issues.Count -gt 0) {
                    $detailText += "`n❌ Issues ($($issues.Count)): " + ($issues -join "; ")
                }
                if ($recommendations.Count -gt 0) {
                    $detailText += "`n💡 Recommendations ($($recommendations.Count)): " + ($recommendations -join "; ")
                }
                
                Add-TestResult -Category "AppProtection" `
                    -TestName "MAM Policy: $($policy.displayName)" `
                    -Status $status `
                    -Details $detailText
            }
        }
        
        $testResults.AppProtection.Summary = @{
            TotalPolicies = $mamPolicies.value.Count
        }
        
    }
    catch {
        Add-TestResult -Category "AppProtection" -TestName "App Protection Access" `
            -Status "Warning" -Details "Unable to access app protection policies: $($_.Exception.Message)"
    }
}

# Test 10: Windows Autopilot Deployment Profiles
function Test-AutopilotProfiles {
    Write-Host "`nTesting Windows Autopilot Profiles..." -ForegroundColor Cyan
    
    try {
        $autopilotProfiles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles"
        
        if ($autopilotProfiles.value.Count -eq 0) {
            Add-TestResult -Category "AutopilotProfiles" -TestName "Autopilot Profiles" `
                -Status "Warning" -Details "No Autopilot profiles found - recommended for modern provisioning"
        }
        else {
            Add-TestResult -Category "AutopilotProfiles" -TestName "Autopilot Profiles Exist" `
                -Status "Pass" -Details "$($autopilotProfiles.value.Count) Autopilot profiles found"
            
            foreach ($profile in $autopilotProfiles.value) {
                $issues = @()
                $strengths = @()
                $recommendations = @()
                
                # Check device name template
                if ($profile.deviceNameTemplate) {
                    $strengths += "Device naming template: $($profile.deviceNameTemplate)"
                }
                else {
                    $recommendations += "Consider using device naming template for standardization"
                }
                
                # Check OOBE settings
                if ($profile.outOfBoxExperienceSettings) {
                    $oobe = $profile.outOfBoxExperienceSettings
                    
                    if ($oobe.hidePrivacySettings -eq $true) {
                        $strengths += "Privacy settings page hidden (streamlined)"
                    }
                    
                    if ($oobe.hideEULA -eq $true) {
                        $strengths += "EULA page hidden (streamlined)"
                    }
                    
                    if ($oobe.userType -eq "standard") {
                        $strengths += "Users created as standard (security best practice)"
                    }
                    elseif ($oobe.userType -eq "administrator") {
                        $issues += "Users created as administrators (security risk)"
                    }
                    
                    if ($oobe.skipKeyboardSelectionPage -eq $true) {
                        $strengths += "Keyboard selection skipped (streamlined)"
                    }
                    
                    if ($oobe.hideEscapeLink -eq $true) {
                        $strengths += "Escape link hidden (prevents OOBE bypass)"
                    }
                    else {
                        $recommendations += "Consider hiding escape link to prevent setup bypass"
                    }
                }
                
                # Check enrollment status page
                if ($profile.enrollmentStatusScreenSettings.hideInstallationProgress -eq $false) {
                    $strengths += "Installation progress shown to users"
                }
                
                if ($profile.enrollmentStatusScreenSettings.blockDeviceSetupRetryByUser -eq $true) {
                    $strengths += "User cannot retry failed setup (controlled environment)"
                }
                
                # Check hybrid Azure AD join
                if ($profile.'@odata.type' -eq "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile") {
                    $strengths += "Hybrid Azure AD join profile configured"
                }
                
                # Determine status
                $status = if ($issues.Count -gt 0) { "Warning" } else { "Pass" }
                
                $detailText = ""
                if ($strengths.Count -gt 0) {
                    $detailText += "`n✓ Configuration ($($strengths.Count)): " + ($strengths -join "; ")
                }
                if ($issues.Count -gt 0) {
                    $detailText += "`n❌ Issues ($($issues.Count)): " + ($issues -join "; ")
                }
                if ($recommendations.Count -gt 0) {
                    $detailText += "`n💡 Recommendations ($($recommendations.Count)): " + ($recommendations -join "; ")
                }
                
                Add-TestResult -Category "AutopilotProfiles" `
                    -TestName "Autopilot Profile: $($profile.displayName)" `
                    -Status $status `
                    -Details $detailText
            }
        }
        
        $testResults.AutopilotProfiles.Summary = @{
            TotalProfiles = $autopilotProfiles.value.Count
        }
        
    }
    catch {
        Add-TestResult -Category "AutopilotProfiles" -TestName "Autopilot Access" `
            -Status "Warning" -Details "Unable to access Autopilot profiles"
    }
}

# Test 11: Assignment Filters
function Test-DeviceFilters {
    Write-Host "`nTesting Assignment Filters..." -ForegroundColor Cyan
    
    try {
        $filters = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters"
        
        if ($filters.value.Count -eq 0) {
            Add-TestResult -Category "DeviceFilters" -TestName "Assignment Filters" `
                -Status "Warning" -Details "No assignment filters found - consider using for targeted deployments"
        }
        else {
            Add-TestResult -Category "DeviceFilters" -TestName "Assignment Filters Exist" `
                -Status "Pass" -Details "$($filters.value.Count) assignment filters configured"
            
            foreach ($filter in $filters.value) {
                $details = "Platform: $($filter.platform) | Rule: $($filter.rule)"
                
                Add-TestResult -Category "DeviceFilters" `
                    -TestName "Filter: $($filter.displayName)" `
                    -Status "Pass" `
                    -Details $details
            }
        }
        
        $testResults.DeviceFilters.Summary = @{
            TotalFilters = $filters.value.Count
        }
        
    }
    catch {
        Add-TestResult -Category "DeviceFilters" -TestName "Device Filters Access" `
            -Status "Warning" -Details "Unable to access assignment filters"
    }
}

# Test 12: PowerShell Scripts and Remediation Scripts
function Test-Scripts {
    Write-Host "`nTesting PowerShell and Remediation Scripts..." -ForegroundColor Cyan
    
    try {
        # PowerShell Scripts
        $psScripts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts"
        
        if ($psScripts.value.Count -gt 0) {
            Add-TestResult -Category "Scripts" -TestName "PowerShell Scripts" `
                -Status "Pass" -Details "$($psScripts.value.Count) PowerShell scripts deployed"
            
            foreach ($script in $psScripts.value) {
                $details = ""
                if ($script.runAsAccount -eq "system") {
                    $details += "Runs as: System | "
                }
                else {
                    $details += "Runs as: User | "
                }
                
                if ($script.enforceSignatureCheck -eq $true) {
                    $details += "Signature check: Enabled (Secure)"
                }
                else {
                    $details += "Signature check: Disabled"
                }
                
                Add-TestResult -Category "Scripts" `
                    -TestName "Script: $($script.displayName)" `
                    -Status "Pass" `
                    -Details $details
            }
        }
        
        # Proactive Remediation Scripts
        $remediationScripts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
        
        if ($remediationScripts.value.Count -gt 0) {
            Add-TestResult -Category "Scripts" -TestName "Proactive Remediations" `
                -Status "Pass" -Details "$($remediationScripts.value.Count) remediation script packages configured"
            
            foreach ($remediation in $remediationScripts.value) {
                $details = "Detection and remediation script package"
                if ($remediation.runAsAccount -eq "system") {
                    $details += " | Runs as: System"
                }
                
                Add-TestResult -Category "Scripts" `
                    -TestName "Remediation: $($remediation.displayName)" `
                    -Status "Pass" `
                    -Details $details
            }
        }
        
        if ($psScripts.value.Count -eq 0 -and $remediationScripts.value.Count -eq 0) {
            Add-TestResult -Category "Scripts" -TestName "PowerShell Scripts" `
                -Status "Warning" -Details "No scripts found - consider using for automation and remediation"
        }
        
        $testResults.Scripts.Summary = @{
            PowerShellScripts  = $psScripts.value.Count
            RemediationScripts = $remediationScripts.value.Count
        }
        
    }
    catch {
        Add-TestResult -Category "Scripts" -TestName "Scripts Access" `
            -Status "Warning" -Details "Unable to access PowerShell scripts"
    }
}

# Test 13: RBAC and Custom Roles
function Test-RBAC {
    Write-Host "`nTesting Role-Based Access Control..." -ForegroundColor Cyan
    
    try {
        $roleDefinitions = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/roleDefinitions"
        $roleAssignments = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/roleAssignments"
        
        Add-TestResult -Category "RBAC" -TestName "Role Definitions" `
            -Status "Pass" -Details "$($roleDefinitions.value.Count) role definitions found"
        
        # Check for custom roles
        $customRoles = $roleDefinitions.value | Where-Object { $_.isBuiltIn -eq $false }
        if ($customRoles.Count -gt 0) {
            Add-TestResult -Category "RBAC" -TestName "Custom Roles" `
                -Status "Pass" -Details "$($customRoles.Count) custom roles defined"
            
            foreach ($role in $customRoles) {
                $permissions = $role.rolePermissions.Count
                Add-TestResult -Category "RBAC" `
                    -TestName "Custom Role: $($role.displayName)" `
                    -Status "Pass" `
                    -Details "$permissions permission(s) defined"
            }
        }
        
        # Check role assignments
        if ($roleAssignments.value.Count -gt 0) {
            Add-TestResult -Category "RBAC" -TestName "Role Assignments" `
                -Status "Pass" -Details "$($roleAssignments.value.Count) role assignments configured"
        }
        else {
            Add-TestResult -Category "RBAC" -TestName "Role Assignments" `
                -Status "Warning" -Details "No role assignments found - ensure proper delegation"
        }
        
        $testResults.RBAC.Summary = @{
            TotalRoles  = $roleDefinitions.value.Count
            CustomRoles = $customRoles.Count
            Assignments = $roleAssignments.value.Count
        }
        
    }
    catch {
        Add-TestResult -Category "RBAC" -TestName "RBAC Access" `
            -Status "Warning" -Details "Unable to access RBAC configuration"
    }
}

# Test 14: Enrollment Tokens and Certificates
function Test-EnrollmentTokens {
    Write-Host "`nTesting Enrollment Tokens and Certificates..." -ForegroundColor Cyan
    
    try {
        # Apple Push Notification Certificate
        try {
            $applePushCert = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/applePushNotificationCertificate"
            
            if ($applePushCert.appleIdentifier) {
                $expirationDate = [DateTime]::Parse($applePushCert.expirationDateTime)
                $daysUntilExpiration = ($expirationDate - (Get-Date)).Days
                
                if ($daysUntilExpiration -lt 30) {
                    Add-TestResult -Category "EnrollmentTokens" -TestName "Apple Push Certificate" `
                        -Status "Fail" -Details "Expires in $daysUntilExpiration days - RENEW IMMEDIATELY"
                }
                elseif ($daysUntilExpiration -lt 60) {
                    Add-TestResult -Category "EnrollmentTokens" -TestName "Apple Push Certificate" `
                        -Status "Warning" -Details "Expires in $daysUntilExpiration days - plan renewal"
                }
                else {
                    Add-TestResult -Category "EnrollmentTokens" -TestName "Apple Push Certificate" `
                        -Status "Pass" -Details "Valid for $daysUntilExpiration days | Apple ID: $($applePushCert.appleIdentifier)"
                }
            }
        }
        catch {
            Add-TestResult -Category "EnrollmentTokens" -TestName "Apple Push Certificate" `
                -Status "Warning" -Details "Not configured or unable to access"
        }
        
        # VPP Tokens
        try {
            $vppTokens = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/vppTokens"
            
            if ($vppTokens.value.Count -gt 0) {
                foreach ($token in $vppTokens.value) {
                    $expirationDate = [DateTime]::Parse($token.expirationDateTime)
                    $daysUntilExpiration = ($expirationDate - (Get-Date)).Days
                    
                    $status = "Pass"
                    $details = "Valid for $daysUntilExpiration days"
                    
                    if ($daysUntilExpiration -lt 30) {
                        $status = "Fail"
                        $details = "Expires in $daysUntilExpiration days - RENEW IMMEDIATELY"
                    }
                    elseif ($daysUntilExpiration -lt 60) {
                        $status = "Warning"
                        $details = "Expires in $daysUntilExpiration days - plan renewal"
                    }
                    
                    Add-TestResult -Category "EnrollmentTokens" `
                        -TestName "VPP Token: $($token.displayName)" `
                        -Status $status `
                        -Details $details
                }
            }
        }
        catch {
            # VPP tokens may not be configured
        }
        
        # DEP Tokens
        try {
            $depTokens = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings"
            
            if ($depTokens.value.Count -gt 0) {
                foreach ($token in $depTokens.value) {
                    $expirationDate = [DateTime]::Parse($token.tokenExpirationDateTime)
                    $daysUntilExpiration = ($expirationDate - (Get-Date)).Days
                    
                    $status = "Pass"
                    $details = "Valid for $daysUntilExpiration days"
                    
                    if ($daysUntilExpiration -lt 30) {
                        $status = "Fail"
                        $details = "Expires in $daysUntilExpiration days - RENEW IMMEDIATELY"
                    }
                    elseif ($daysUntilExpiration -lt 60) {
                        $status = "Warning"
                        $details = "Expires in $daysUntilExpiration days - plan renewal"
                    }
                    
                    Add-TestResult -Category "EnrollmentTokens" `
                        -TestName "Apple DEP Token: $($token.appleIdentifier)" `
                        -Status $status `
                        -Details $details
                }
            }
        }
        catch {
            # DEP tokens may not be configured
        }
        
        # Android Enterprise Binding
        try {
            $androidBinding = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"
            
            if ($androidBinding.bindStatus -eq "bound") {
                Add-TestResult -Category "EnrollmentTokens" -TestName "Android Enterprise Binding" `
                    -Status "Pass" -Details "Bound to managed Google Play | Organization: $($androidBinding.ownerOrganizationName)"
            }
            else {
                Add-TestResult -Category "EnrollmentTokens" -TestName "Android Enterprise Binding" `
                    -Status "Warning" -Details "Not bound to managed Google Play"
            }
        }
        catch {
            Add-TestResult -Category "EnrollmentTokens" -TestName "Android Enterprise Binding" `
                -Status "Warning" -Details "Unable to verify Android Enterprise binding"
        }
        
    }
    catch {
        Add-TestResult -Category "EnrollmentTokens" -TestName "Enrollment Tokens Access" `
            -Status "Warning" -Details "Unable to access enrollment tokens"
    }
}

# Main execution
try {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Microsoft Intune Configuration Testing Tool" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    # Connect to Graph
    Connect-ToGraph -TenantId $TenantId
    
    # Get tenant info
    $context = Get-MgContext
    $testResults.TenantInfo = @{
        TenantId = $context.TenantId
        Account  = $context.Account
        Scopes   = $context.Scopes
    }
    
    # Run all tests
    Test-BestPractices
    Test-CompliancePolicies
    Test-ConfigurationProfiles
    Test-ConditionalAccessPolicies
    Test-Applications
    Test-AppProtectionPolicies
    Test-EndpointSecurity
    Test-EnrollmentSettings
    Test-AutopilotProfiles
    Test-DeviceFilters
    Test-Scripts
    Test-RBAC
    Test-EnrollmentTokens
    Test-Monitoring
    
    # Generate report
    Write-Host "`nGenerating HTML report..." -ForegroundColor Cyan
    $reportPath = Generate-HTMLReport -Results $testResults -OutputPath $OutputPath
    
    # Display summary
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Total Tests: $($testResults.Summary.TotalTests)" -ForegroundColor White
    Write-Host "Passed: $($testResults.Summary.PassedTests)" -ForegroundColor Green
    Write-Host "Failed: $($testResults.Summary.FailedTests)" -ForegroundColor Red
    Write-Host "Warnings: $($testResults.Summary.WarningTests)" -ForegroundColor Yellow
    Write-Host "`nReport saved to: $reportPath" -ForegroundColor Cyan
    
    # Open report in default browser
    $openReport = Read-Host "`nWould you like to open the report now? (Y/N)"
    if ($openReport -eq 'Y' -or $openReport -eq 'y') {
        Start-Process $reportPath
    }
    
}
catch {
    Write-Host "`nError during execution: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Disconnect from Graph
    Write-Host "`nDisconnecting from Microsoft Graph..." -ForegroundColor Cyan
    Disconnect-MgGraph
}
