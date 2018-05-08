<powershell>
# Install Cygwin + OpenSSH
param ( $TempCygDir="$env:temp\cygInstall" )
if(!(Test-Path -Path $TempCygDir -PathType Container))
{
   $null = New-Item -Type Directory -Path $TempCygDir -Force
}
$client = new-object System.Net.WebClient
$client.DownloadFile("https://cygwin.com/setup-x86_64.exe", "$TempCygDir\setup.exe" )
Start-Process -wait -FilePath "$TempCygDir\setup.exe" -ArgumentList "-q -n -l $TempCygDir -s http://mirrors.kernel.org/sourceware/cygwin/ -R c:\Cygwin64"
Start-Process -wait -FilePath "$TempCygDir\setup.exe" -ArgumentList "-q -n -l $TempCygDir -s http://mirrors.kernel.org/sourceware/cygwin/ -R c:\Cygwin64 -P openssh,cygrunsrv,curl,vim,wget,python,xmlstarlet"
Start-Process -wait -FilePath "$TempCygDir\setup.exe" -ArgumentList "-q -n -l $TempCygDir -K http://cygwinports.org/ports.gpg -s http://mirrors.kernel.org/sourceware/cygwin/ -R c:\Cygwin64 -P python-boto,jq"

# Configure password less login
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "touch /etc/group"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "touch /etc/passwd"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "chmod +r /etc/passwd"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "chmod +r /etc/group"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "chown :None /var"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "chmod 755 /var"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "/usr/bin/ssh-host-config --yes --user ec2-user --pwd P@ssw0rdP@ssw0rd"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "mkdir -p /home/ec2-user/.ssh"'
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile("http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key", "c:/cygwin64/home/ec2-user/.ssh/authorized_keys")
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "chown -R ec2-user /home/ec2-user"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "/usr/bin/chmod 755 /home/ec2-user"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "/usr/bin/chmod -R 600 /home/ec2-user/.ssh"'


# Open up port 22 on the firewall
$fw = New-Object -ComObject hnetcfg.fwpolicy2
$rule = New-Object -ComObject HNetCfg.FWRule
$rule.Name = "ssh"
$rule.Protocol = 6
$rule.LocalPorts = 22
$rule.Enabled = $true
$rule.Profiles = 7 # all
$rule.Action = 1 # NET_FW_ACTION_ALLOW
$rule.EdgeTraversal = $false
$fw.Rules.Add($rule)

# Workaround for - "Expected privileged user ec2-user does not exists"
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "cygrunsrv --remove sshd"'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "/usr/bin/ssh-host-config --yes --user ec2-user --pwd P@ssw0rdP@ssw0rd"'


# Install Chef client
Write-Output "Installing Chef client ..."
if (!(Test-Path "C:\Windows\Temp\chef.msi"))
{
        (New-Object System.Net.WebClient).DownloadFile('https://packages.chef.io/stable/windows/2008r2/chef-client-12.16.42-1-x64.msi', 'C:\Windows\Temp\chef.msi')
}
cmd /c 'msiexec /qb /i C:\Windows\Temp\chef.msi'

# Install pGina
# First we need to install visual studio c++ 2012 redistribution packages for x86 and x64
Write-Output "Installing VC 2012 x86 redistributable package ..."
if (!(Test-Path "C:\Windows\Temp\pgina.exe"))
{
   (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe', 'C:\Windows\Temp\vcredist_x86.exe')
}
cmd /c 'C:\Windows\Temp\vcredist_x86.exe /q /norestart'

Write-Output "Installing VC 2012 x64 redistributable package ..."
if (!(Test-Path "C:\Windows\Temp\pgina.exe"))
{
   (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe', 'C:\Windows\Temp\vcredist_x64.exe')
}
cmd /c 'C:\Windows\Temp\vcredist_x64.exe /q /norestart'

# Install pGina
Write-Output "Installing pGina ..."
if (!(Test-Path "C:\Windows\Temp\pgina.exe"))
{
        (New-Object System.Net.WebClient).DownloadFile('https://github.com/pgina/pgina/releases/download/v3.1.8.0/pGinaSetup-3.1.8.0.exe', 'C:\Windows\Temp\pgina.exe')
}
cmd /c 'C:\Windows\Temp\pgina.exe /silent'

# Disable Windows updates
$RunningAsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($RunningAsAdmin)
{
	$Updates = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings
	if ($Updates.ReadOnly -eq $True) { Write-Error "Cannot update Windows Update settings due to GPO restrictions." }
	else {
		$Updates.NotificationLevel = 1 #Disabled
		$Updates.Save()
		$Updates.Refresh()
		Write-Output "Automatic Windows Updates disabled."
	}
}

#Disable Microsoft Customer Experience Program
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "AitAgent"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "ProgramDataUpdater"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Consolidator"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "KernelCeipTask"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "UsbCeip"

# Disable password authentication for ssh service
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "echo PasswordAuthentication no >>/etc/sshd_config "'
Start-Process -wait -FilePath "C:\Cygwin64\bin\bash.exe" -ArgumentList '--login -c "echo ChallengeResponseAuthentication no >>/etc/sshd_config "'

# Change logon banner
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system' -Name 'legalnoticecaption' 'Adobe Systems'
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system' -Name 'legalnoticetext' 'This is a secure site containing proprietary and confidential information of Adobe Systems. Only authorized Adobe employees, and consultants and business partners who have entered into an appropriate agreement with Adobe, may access this information. Unauthorized use is prohibited.'

# Install BitLocker
Install-WindowsFeature BitLocker -IncludeAllSubFeature -IncludeManagementTools

# Install Windows Container feature
Install-WindowsFeature -Name Containers

# Set password expiry as false
cmd /c 'net accounts /maxpwage:unlimited'

# Changing swap file size to 4GB
cmd /c 'wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False'
cmd /c 'wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=4096,MaximumSize=4096'

# Start ssh service
cmd /c 'sc config sshd start=demand'
cmd /c 'net start sshd'

</powershell>
