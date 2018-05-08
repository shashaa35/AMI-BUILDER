SET chocolateyVersion=0.9.9.12
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
choco install pstools -y
:: psexec -accepteula -s schtasks /change /tn "Microsoft\Windows\TaskScheduler\Maintenance Configurator" /disable
:: psexec -s schtasks /change /tn "Microsoft\Windows\TaskScheduler\Regular Maintenance" /disable
exit
