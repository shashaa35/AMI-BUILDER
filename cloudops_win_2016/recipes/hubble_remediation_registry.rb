#
# Cookbook:: cloudops_win_2016
# Recipe:: hubble_remediation_registry
#
# Copyright:: 2017
# Author:: lmalik
#
# All Rights Reserved - Do Not Redistribute

# 19.7.39.1 (L1) Ensure 'Always install with elevated privileges' is set to 'Disabled'
registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer' do
  values [{name: 'AlwaysInstallElevated', type: :dword, data: 0}
         ]
  recursive true
  action :create
end

# 18.9.52.3.9.1 (L1) Ensure 'Always prompt for password upon connection' is set to 'Enabled'
registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' do
  values [{name: 'fPromptForPassword', type: :dword, data: 1}
         ]
  recursive true
  action :create
end

#CIS-18.9.52.3.10.1 (L2) Ensure 'Set time limit for active but idle Remote Desktop Services sessions' is set to 'Enabled: 15 minutes or less'
#For PCI compliance , we are setting this value as 5 mins
registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' do
  values [{name: 'MaxIdleTime', type: :dword, data: 300000}
         ]
  recursive true
  action :create
end

# 18.4.4.1 (L1) Set 'NetBIOS node type' to 'P-node' (Ensure NetBT Parameter 'NodeType' is set to '0...
registry_key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' do
  values [{name: 'NodeType', type: :dword, data: 2}
         ]
  recursive true
  action :create
end

# 18.9.16.1 (L1) Ensure 'Allow Telemetry' is set to 'Enabled: 0 - Security [Enterprise Only]'
registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection' do
  values [{name: 'AllowTelemetry', type: :dword, data: 0}
         ]
  recursive true
  action :create
end

