
REM Script to download public key of AWS key pair for ssh logins
C:\Cygwin64\bin\bash.exe --login -c '/usr/bin/chmod -R 666 /home/ec2-user/.ssh'
C:\Cygwin64\bin\bash.exe --login -c '/usr/bin/wget http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key -O c:/cygwin64/home/ec2-user/.ssh/authorized_keys'
C:\Cygwin64\bin\bash.exe --login -c 'chown -R ec2-user /home/ec2-user'
C:\Cygwin64\bin\bash.exe --login -c '/usr/bin/chmod 755 /home/ec2-user'
C:\Cygwin64\bin\bash.exe --login -c '/usr/bin/chmod -R 600 /home/ec2-user/.ssh'

REM Script to execute chef recipe from chef-org, if userdata is passed
C:\Cygwin64\bin\bash.exe --login -c 'bash /home/ec2-user/cookbooks/cloudops_win/ami/config_chef.sh'

REM Start SSH daemon
net start "CYGWIN sshd"
