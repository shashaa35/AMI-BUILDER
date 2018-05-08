#
# Cookbook Name:: cloudops_win_2016
# Recipe:: default
#
# Copyright 2017, Adobe Systems, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Install hubble
include_recipe 'hubble'

#Install azure-cli
include_recipe 'co-awsazurecli'
include_recipe 'cloudops_win_2016::hubble_remediation_gpedit'
include_recipe 'cloudops_win_2016::hubble_remediation_registry'
