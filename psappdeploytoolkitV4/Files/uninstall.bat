tasklist /fi "imagename eq csc_ui.exe" |find ":" > nul
if errorlevel 1 taskkill /f /im "csc_ui.exe"

tasklist /fi "imagename eq dnscryptproxy.exe" |find ":" > nul
if errorlevel 1 taskkill /f /im "dnscryptproxy.exe"

tasklist /fi "imagename eq vpnagent.exe" |find ":" > nul
if errorlevel 1 taskkill /f /im "vpnagent.exe"

tasklist /fi "imagename eq acumbrellaagent.exe" |find ":" > nul
if errorlevel 1 taskkill /f /im "acumbrellaagent.exe"

msiexec.exe /x "%SpecopsDeployExecuteDir%\cisco-secure-client-win-5.1.0.136-umbrella-predeploy-k9.msi" /quiet
msiexec.exe /x "%SpecopsDeployExecuteDir%\cisco-secure-client-win-5.1.0.136-dart-predeploy-k9.msi" /quiet
msiexec.exe /x "%SpecopsDeployExecuteDir%\cisco-secure-client-win-5.1.0.136-core-vpn-predeploy-k9.msi" /quiet

