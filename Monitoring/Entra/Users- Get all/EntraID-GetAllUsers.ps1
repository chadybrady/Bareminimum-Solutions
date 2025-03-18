Write-Host "Created by Tim Hjort, 2025"
Write-Host "Bareminimum Solutions"

## Check if Microsoft.Entra module is already installed
if (!(Get-Module -ListAvailable -Name Microsoft.Entra)) {
    Write-Host "Microsoft.Entra module not found. Installing..."
    Install-Module -Name Microsoft.Entra -Repository PSGallery -Scope CurrentUser -Force -AllowClobber
    Write-Host "Microsoft.Entra module installed successfully."
} 

## Check if module is imported and import if not
if (!(Get-Module -Name Microsoft.Entra)) {
    Write-Host "Importing Microsoft.Entra module..."
    Import-Module Microsoft.Entra
    Write-Host "Microsoft.Entra module imported successfully."
} else {
    Write-Host "Microsoft.Entra module is already imported."
}

## Try to connect to Entra ID, handle any authentication errors
try {
    Write-Host "Connecting to Entra ID..."
    Connect-Entra
    Write-Host "Successfully connected to Entra ID."
} catch {
    Write-Host "Failed to connect to Entra ID: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

## Runs the command to export all entra id users to a csv file
try {
    Write-Host "Getting Entra ID users..."
    $users = Get-EntraUser -All
    Write-Host "Retrieved $($users.Count) users."
    
    Write-Host "Exporting Entra ID users to CSV..."
    $users | Select-Object UserPrincipalName, DisplayName, ObjectId, OnPremisesSyncEnabled | Export-Csv -Path "EntraIDUsers.csv" -NoTypeInformation
    Write-Host "Entra ID users exported to EntraIDUsers.csv"
} catch {
    Write-Host "Failed to export Entra ID users: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception | Format-List -Force)" -ForegroundColor Red
}