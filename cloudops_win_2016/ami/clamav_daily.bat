@echo off

rem Script to scan file system with ClamAV

cd c:\ClamAV
mkdir c:\ClamAV\db
del /Q scan.log

rem Update virus definitions
echo **** Updating definitions
echo DatabaseDirectory c:/clamAV/db > freshclam.conf
echo DatabaseMirror database.clamav.net >> freshclam.conf
c:\ClamAV\freshclam --quiet

rem scan the system
echo **** Scanning...
c:\ClamAV\clamscan --log=c:\ClamAV\scan.log --recursive --infected --exclude=icwconn1.exe --exclude=.*.msp --exclude=ntuser.dat.* --exclude=NTUSER.DAT.* --exclude=UsrClass.dat.* --exclude-dir=C:\WINDOWS\system32\config --database=c:\ClamAV\db c:\

echo **** Scanning finished

