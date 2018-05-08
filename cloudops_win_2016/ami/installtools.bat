SET chocolateyVersion=0.9.9.12
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
choco install sysinternals -y
choco install notepadplusplus -y
choco install 7zip.install -y
exit
