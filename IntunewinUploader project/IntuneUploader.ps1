# Function to read credentials from config file
function Read-Config {
    param([string]$FilePath)
    $Config = @{}

    if (Test-Path $FilePath) {
        Get-Content $FilePath | ForEach-Object {
            $Key, $Value = $_ -split "=", 2
            $Config[$Key] = $Value
        }
    } else {
        Write-Error "Config file not found: $FilePath"
        exit 1
    }
    return $Config
}

# Read credentials from config.txt
$ConfigPath = ".\config.txt"
$Config = Read-Config -FilePath $ConfigPath

$IntuneTenantId = $Config["TenantID"]
$ClientId = $Config["ClientID"]
$ClientSecret = $Config["ClientSecret"]

# Prompt user for input
function Prompt-Input($message) {
    $inputValue = Read-Host -Prompt $message
    return $inputValue
}

$SourceFolder = Prompt-Input "Enter the source folder path (where app files are located)"
$OutputFolder = Prompt-Input "Enter the output folder path (where .intunewin will be saved)"
$AppName = Prompt-Input "Enter the application name"
$AppVersion = Prompt-Input "Enter the application version"

# Define paths
$ProjectRoot = (Get-Location).Path
$IntuneWinToolPath = "$ProjectRoot\intunewinprepptool\IntuneWinAppUtil.exe"
$OutputFile = "$OutputFolder\$AppName-$AppVersion.intunewin"

# Ensure output folder exists
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

Write-Host "Creating .intunewin package..."
Start-Process -FilePath $IntuneWinToolPath -ArgumentList "-c `"$SourceFolder`" -s setup.exe -o `"$OutputFolder`"" -NoNewWindow -Wait

if (!(Test-Path $OutputFile)) {
    Write-Error "Failed to create .intunewin file!"
    exit 1
}

Write-Host "Extracting metadata..."
$MetadataJson = "$OutputFolder\metadata.json"
& "$IntuneWinToolPath" -d "$OutputFile" -o "$OutputFolder"

if (Test-Path $MetadataJson) {
    $Metadata = Get-Content -Path $MetadataJson | ConvertFrom-Json
    Write-Host "App Name: $($Metadata.Name)"
    Write-Host "Version: $($Metadata.Version)"
} else {
    Write-Host "No metadata found."
}

Write-Host "Uploading to Intune..."

# Get access token for Microsoft Graph API
$Body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
} | ConvertTo-Json -Compress

$Headers = @{
    "Content-Type"  = "application/x-www-form-urlencoded"
}

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$IntuneTenantId/oauth2/v2.0/token" -Method Post -Body $Body -Headers $Headers
$AccessToken = $TokenResponse.access_token

# Upload app to Intune
$UploadHeaders = @{
    "Authorization" = "Bearer $AccessToken"
    "Content-Type"  = "application/octet-stream"
}

$FileBytes = [System.IO.File]::ReadAllBytes($OutputFile)
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps" -Method Post -Body $FileBytes -Headers $UploadHeaders

Write-Host "Upload completed successfully!"