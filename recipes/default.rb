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

install_path       = node['acadock']['install_path']
download_dest_path = File.join Chef::Config[:file_cache_path], filename
acadock_dir        = File.join install_path, basename

remote_file download_dest_path do
  source download_url
end

bash "extract acadock-monitoring #{node['acadock']['version'] }" do
  code <<-EOH
    tar -C #{install_path} -xvf #{download_dest_path}
  EOH
  creates "#{acadock_dir}/acadock-monitoring"
  action :nothing
end

template "/etc/init/acadock-monitoring.conf" do
  source 'acadock-monitoring.conf.erb'
  mode 0664
  variables({
    docker_url: node['acadock']['docker_url'],
    target: File.join(acadock_dir "acadock-monitoring"),
    port: node['acadock']['port'],
  })
  notifies :stop, "service[acadock-monitoring]", :delayed
  notifies :start, "service[acadock-monitoring]", :delayed
end

service 'acadock-monitoring' do
  provider Chef::Provider::Service::Upstart
  subscribes :restart, "remote_file[#{download_dest_path}]"
  action [:enable]
end

