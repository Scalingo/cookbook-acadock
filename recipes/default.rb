#
# Cookbook Name:: acadock
# Recipe:: default
#
# Copyright 2014, Soulou
#
# License MIT
#
 
filename = "acadock-monitoring-" +
           node['acadock']['version'] + "-linux-" +
           node['acadock']['arch'] + ".tar.gz"
basename = File.basename filename

download_url = 
  node['acadock']['download_url'] + "/" +
  node['acadock']['version'] + "/" + filename

dest_path = "#{Chef::Config[:file_cache_path]}/#{filename}"
extract_dir_path = "#{Chef::Config[:file_cache_path]}/#{basename}"

remote_file dest_path do
  source download_url
end

bash "extract acadock-monitoring #{node['acadock']['version'] }" do
  code <<-EOH
    tar -C "#{extract_dir_path}" -xvf #{dest_path}
    cp "#{extract_dir_path}/acadocker-monitoring" "#{node['acadock']['install_path']}"
  EOH
  subscribes :run, "remote_file[#{dest_path}]"
  action :nothing
end

template "/etc/init/acadock-monitoring.conf" do
  source 'acadock-monitoring.conf.erb'
  mode 0664
  variables({
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

