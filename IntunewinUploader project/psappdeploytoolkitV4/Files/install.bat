@echo off

msiexec /package cisco-secure-client-win-5.1.0.136-core-vpn-predeploy-k9.msi /norestart /passive PRE_DEPLOY_DISABLE_VPN=1 /lvx* vpninstall.log
msiexec /package cisco-secure-client-win-5.1.0.136-dart-predeploy-k9.msi /norestart /passive LOCKDOWN=1 /lvx* umbrellainstall.log
msiexec /package cisco-secure-client-win-5.1.0.136-umbrella-predeploy-k9.msi /norestart /passive /lvx* dartinstall.log