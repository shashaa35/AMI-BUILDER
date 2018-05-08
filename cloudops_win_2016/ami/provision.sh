#!/bin/bash

# Run chef recipes
cmd /c 'c:/opscode/chef/bin/chef-client -v'
cmd /c 'c:/opscode/chef/bin/chef-client --local -r recipe[cloudops_win_2016::default]'

# Set a script for getting public key on every boot
cmd /c 'schtasks /create /tn BootUpTasks /tr c:\cygwin64\home\ec2-user\cookbooks\cloudops_win_2016\ami\config_bootup_tasks.bat /sc onstart /RU system'

# Install Clam AV
cmd /c 'start /wait msiexec /package c:\cygwin64\home\ec2-user\cookbooks\cloudops_win_2016\files\clamav-0.99.3-win32.msi /quiet /norestart TARGETDIR=c:\ClamAV'
# Schedule nightly scans of Clam AV
cmd /c 'schtasks /create /tn DailyClamAVScan /sc daily /tr c:\cygwin64\home\ec2-user\cookbooks\cloudops_win_2016\ami\clamav_daily.bat /st 02:00:00 /RU System'

# Set NTP configurations
cmd /c 'sc triggerinfo w32time delete'
cmd /c 'sc config w32time start=auto'
cmd /c 'net start w32time'
cmd /c 'w32tm /config /syncfromflags:manual /manualpeerlist:0.amazon.pool.ntp.org /update /reliable:yes'

# Disable ec2-user user - so that rdp session can not be established by this user
chmod 777 /home/ec2-user/cookbooks/cloudops_win_2016/files/ntrights.exe
cmd /c "c:/cygwin64/home/ec2-user/cookbooks/cloudops_win_2016/files/ntrights.exe -u ec2-user +r SeDenyRemoteInteractiveLogonRight"

# Resize AMI
chmod 777 /home/ec2-user/cookbooks/cloudops_win_2016/files/diskresize.txt
cmd /c "diskpart /s c:/cygwin64/home/ec2-user/cookbooks/cloudops_win_2016/files/diskresize.txt"

# Cleanup
cmd /c "rm c:/cygwin64/home/ec2-user/.ssh/authorized_keys"

# Stop services which are not required
cmd /c 'sc config winrm start=demand'

#Windows Update
# chmod -R 777 /home/ec2-user/cookbooks/cloudops_win_2016/files/PSWindowsUpdate
# curr_exec_policy=$(powershell -Command "& {Get-ExecutionPolicy}")
# powershell -Command "& {Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force}"
# powershell -Command "& {ipmo 'c:\cygwin64\home\ec2-user\cookbooks\cloudops_win_2016\files\PSWindowsUpdate'; Get-WUInstall -AcceptAll -AutoReboot}"
# #powershell -Command "& {Set-ExecutionPolicy -ExecutionPolicy $curr_exec_policy -Scope CurrentUser -Force}"

