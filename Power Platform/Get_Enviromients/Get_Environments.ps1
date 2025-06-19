#Created by Tim Hjort, 2025
#Used to retrieve and export power platform environments

$requiredModules = @(
    'Microsoft.PowerApps.Administration.PowerShell',
    'Microsoft.PowerApps.PowerShell'
)

foreach ($module in $requiredModules) {
    try {
        if (-not (Get-Module -Name $module -ListAvailable)) {
            Write-Host "Installing module: $module"
            Install-Module -Name $module -Force -Scope CurrentUser -ErrorAction Stop -AllowClobber -RequiredVersion "2.0.212"
        } else {
            Write-Host "Module $module is already installed."
        }

        # Import module with verbose output for troubleshooting
        Import-Module $module -ErrorAction Stop -Verbose
        Write-Host "Module $module has been imported." -ForegroundColor Green
    } catch {
        Write-Error "Failed to install or import module $module : $_"
        exit
    }
}
