#
# Cookbook:: cloudops_win_2016
# Recipe:: hubble_remediation_gpedit
#
# Copyright:: 2017
# Author:: shasagar
#
# All Rights Reserved - Do Not Redistribute

template 'C:\temp\gpedit.inf' do
  source 'gpedit.inf.erb'
end

execute 'edit group policy' do
  command 'secedit /configure /db c:\Windows\security\database\secedit2.sdb /cfg C:\temp\gpedit.inf'
end

file 'C:\temp\gpedit.inf' do
action :delete
end
