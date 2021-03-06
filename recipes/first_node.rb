#
# Cookbook:: lxc-host
# Recipe:: first_node
#
# Copyright:: 2018, BaritoLog.
#
#

if node[cookbook_name][:custom_ipaddress].nil?
  node_ipaddress = node[:ipaddress]
else
  node_ipaddress = node[cookbook_name][:custom_ipaddress]
end

include_recipe "#{cookbook_name}::install"

template '/etc/default/lxd_preseed.yml' do
  source 'etc/default/first_node_preseed.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(:lxd_bind_address =>  node_ipaddress,
            :lxd_cluster_password => node[cookbook_name][:lxd_cluster_password],
            :server_name => node.name,
            :network_bridge_name => node[cookbook_name][:network_bridge_name],
            :underlay_subnet => node[cookbook_name][:underlay_subnet],
            :overlay_subnet => node[cookbook_name][:overlay_subnet],
            :storage_pool_source => node[cookbook_name][:storage_pool_source],
            :storage_pool_name => node[cookbook_name][:storage_pool_name],
            :storage_pool_driver => node[cookbook_name][:storage_pool_driver],
            :ssh_authorized_key => node[cookbook_name][:ssh_authorized_key])
end

execute "wait for LXD to be initialized" do
  command "sleep 10"
end

execute 'create preseed-finished' do
  command 'touch /var/snap/lxd/common/lxd/preseed-finished'
  user 'root'
  group 'root'
  action :nothing
end

execute 'lxd init' do
  not_if { ::File.exist?('/var/snap/lxd/common/lxd/preseed-finished') }
  command "cat /etc/default/lxd_preseed.yml | sudo lxd init --preseed"
  notifies :run, 'execute[create preseed-finished]', :immediately
end

include_recipe "#{cookbook_name}::optimize"
include_recipe "#{cookbook_name}::sauron_register"
