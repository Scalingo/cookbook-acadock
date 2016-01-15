#
# Cookbook Name:: acadock
# Recipe:: default
#
# Copyright 2014, Soulou
#
# License MIT
#
 
basename = "acadock-monitoring_" +
           node['acadock']['version'] + "_linux_" +
           node['acadock']['arch']
filename = "#{basename}.tar.gz"

download_url = 
  node['acadock']['download_url'] + "/v" +
  node['acadock']['version'] + "/" + filename

dest_path = "#{Chef::Config[:file_cache_path]}/#{filename}"
extract_dir_path = "#{Chef::Config[:file_cache_path]}/#{basename}"

remote_file dest_path do
  source download_url
end

bash "extract acadock-monitoring #{node['acadock']['version'] }" do
  code <<-EOH
    tar -C "#{Chef::Config[:file_cache_path]}" -xvf #{dest_path}
    cp -f "#{extract_dir_path}/acadock-monitoring-ns-netstat" "#{node['acadock']['install_path']}"
    cp -f "#{extract_dir_path}/server" "#{node['acadock']['install_path']}/acadock-monitoring"
  EOH
  subscribes :run, "remote_file[#{dest_path}]"
  action :nothing
end

template "/etc/init/acadock-monitoring.conf" do
  source 'acadock-monitoring.conf.erb'
  mode 0664
  variables({
    docker_url: node['acadock']['docker_url'],
    target: File.join(node['acadock']['install_path'], "acadock-monitoring"),
    port: node['acadock']['port']
  })
  notifies :stop, "service[acadock-monitoring]", :delayed
  notifies :start, "service[acadock-monitoring]", :delayed
end

service 'acadock-monitoring' do
  provider Chef::Provider::Service::Upstart
  subscribes :restart, "remote_file[#{dest_path}]"
  action [:enable]
end

