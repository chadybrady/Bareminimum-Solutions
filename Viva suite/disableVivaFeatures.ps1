##Powershell Modules

# Install the required PowerShell modules if not already installed
$InstallModule = Read-Host "Do you want to install the required PowerShell modules? (Y/N)"
if ($InstallModule -eq "Y") {
    Write-Host "Installing required PowerShell modules..." -ForegroundColor Green
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
    Install-Module -Name MicrosoftTeams -Force -AllowClobber
} else {
    Write-Host "Skipping module installation. Ensure you have the required modules installed." -ForegroundColor Yellow
}


Write-Host "Connecting to Exchange Online Management" -ForegroundColor Green
try {
    Connect-ExchangeOnline 
    Write-Host "Successfully connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Exchange Online. Please ensure you have the necessary permissions."
    exit 1
}

$AlreadyConfiguredPolicies = Read-Host "Have you already configured any Viva policies? (Y/N)"
if ($AlreadyConfiguredPolicies -eq "Y"){
    Remove-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId CustomizationControl -Name DisableFeatureForAllCustomizationControl -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId PulseConversation -Name DisableFeatureForAllPulseConversation -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId CopilotInVivaPulse -Name DisableFeatureForAllCopilotInVivaPulse -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId PulseExpWithM365Copilot -Name DisableFeatureForAllPulseExpWithM365Copilot -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId PulseDelegation -Name DisableFeatureForAllPulseDelegation -Scope Everyone -ErrorAction SilentlyContinue   
    Remove-VivaModuleFeaturePolicy -ModuleId VivaGoals -FeatureId CopilotInVivaGoals -Name DisableFeatureForAllCopilotInVivaGoals -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaGlint -FeatureId CopilotInVivaGlint -Name DisableFeatureForAllCopilotInVivaGlint -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaEngage -FeatureId AISummarization -Name DisableFeatureForAllAISummarization -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaEngage -FeatureId CopilotInVivaEngage -Name DisableFeatureForAllCopilotInVivaEngage -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId Reflection -Name DisableFeatureForAllReflection -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotDashboard -Name DisableFeatureForAllCopilotDashboard -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId DigestWelcomeEmail -Name DisableFeatureForAllDigestWelcomeEmail -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId AutoCxoIdentification -Name DisableFeatureForAllAutoCxoIdentification -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId MeetingCostAndQuality -Name DisableFeatureForAllMeetingCostAndQuality -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotDashboardDelegation -Name DisableFeatureForAllCopilotDashboardDelegation -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId AnalystReportPublish -Name DisableFeatureForAllAnalystReportPublish -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotInVivaInsights -Name DisableFeatureForAllCopilotInVivaInsights -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId AdvancedInsights -Name DisableFeatureForAllAdvancedInsights -Scope Everyone -ErrorAction SilentlyContinue
    Remove-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotChatInVivaInsights -Name DisableFeatureForAllCopilotChatInVivaInsights -Scope Everyone -ErrorAction SilentlyContinue
    Write-Host "Removed existing Viva policies." -ForegroundColor Green
} else {
    Write-Host "No existing Viva policies to remove." -ForegroundColor Yellow
}

Write-Host "Configuring Viva policies to disable features..." -ForegroundColor Green
##Viva Pulse Features
Write-Host "Configuring Viva Pulse Features..." -ForegroundColor Green
Add-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId CustomizationControl -Name DisableFeatureForAllCustomizationControl -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId PulseConversation -Name DisableFeatureForAllPulseConversation -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId CopilotInVivaPulse -Name DisableFeatureForAllCopilotInVivaPulse -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId PulseExpWithM365Copilot -Name DisableFeatureForAllPulseExpWithM365Copilot -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaPulse -FeatureId PulseDelegation -Name DisableFeatureForAllPulseDelegation -IsFeatureEnabled $false -Everyone
##Viva Goals Features
Write-Host "Configuring Viva Goals Features..." -ForegroundColor Green
Add-VivaModuleFeaturePolicy -ModuleId VivaGoals -FeatureId CopilotInVivaGoals -Name DisableFeatureForAllCopilotInVivaGoals -IsFeatureEnabled $false -Everyone
##Viva Glint Features
Write-Host "Configuring Viva Glint Features..." -ForegroundColor Green
Add-VivaModuleFeaturePolicy -ModuleId VivaGlint -FeatureId CopilotInVivaGlint -Name DisableFeatureForAllCopilotInVivaGlint -IsFeatureEnabled $false -Everyone
##Viva Engage Features
Write-Host "Configuring Viva Engage Features..." -ForegroundColor Green
Add-VivaModuleFeaturePolicy -ModuleId VivaEngage -FeatureId AISummarization -Name DisableFeatureForAllAISummarization -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaEngage -FeatureId CopilotInVivaEngage -Name DisableFeatureForAllCopilotInVivaEngage -IsFeatureEnabled $false -Everyone
##Viva Insights Features
Write-Host "Configuring Viva Insights Features..." -ForegroundColor Green
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId Reflection -Name DisableFeatureForAllReflection -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotDashboard -Name DisableFeatureForAllCopilotDashboard -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId DigestWelcomeEmail -Name DisableFeatureForAllDigestWelcomeEmail -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId AutoCxoIdentification -Name DisableFeatureForAllAutoCxoIdentification -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId MeetingCostAndQuality -Name DisableFeatureForAllMeetingCostAndQuality -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotDashboardDelegation -Name DisableFeatureForAllCopilotDashboardDelegation -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId AnalystReportPublish -Name DisableFeatureForAllAnalystReportPublish -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotInVivaInsights -Name DisableFeatureForAllCopilotInVivaInsights -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId AdvancedInsights -Name DisableFeatureForAllAdvancedInsights -IsFeatureEnabled $false -Everyone
Add-VivaModuleFeaturePolicy -ModuleId VivaInsights -FeatureId CopilotChatInVivaInsights -Name DisableFeatureForAllCopilotChatInVivaInsights -IsFeatureEnabled $false -Everyone


Write-Host "Connecting to Teams Online Management" -ForegroundColor Green
try {
    Connect-MicrosoftTeams
    Write-Host "Successfully connected to Teams Online" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Teams Online. Please ensure you have the necessary permissions."
    exit 1
}
