#
# Cookbook Name:: acadock
# Recipe:: default
#
# Copyright 2014, Soulou
#
# License MIT
#

download_url = 
  node['acadock']['download_url'] + "/" +
  node['acadock']['version'] + "/acadock-monitoring-" +
  node['acadock']['version'] + "-" +
  node['acadock']['arch'] + ".tar.xz" 

dest_path = "#{Chef::Config[:file_cache_path]}/acadock-monitoring.tar.xz"

remote_file dest_path do
  source download_url
end

bash "extract acadock-monitoring #{node['acadock']['version'] }" do
  code <<-EOH
    tar -C #{node['acadock']['install_path']} -xvf #{dest_path}
  EOH
end

