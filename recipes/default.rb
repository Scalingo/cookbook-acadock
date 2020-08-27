#
# Cookbook Name:: acadock
# Recipe:: default
#
# Copyright 2014, Soulou
#
# License MIT
#

basename = 'acadock-monitoring_' +
           node['acadock']['version'] + '_linux_' +
           node['acadock']['arch']
filename = "#{basename}.tar.gz"

download_url =
  node['acadock']['download_url'] + '/v' +
  node['acadock']['version'] + '/' + filename

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
end

env = [
  "PORT=#{node['acadock']['port']}",
  "DOCKER_URL=#{node['acadock']['docker_url']}",
]

if !node['acadock']['http_username'].nil? && !node['acadock']['http_password'].nil?
  env << "HTTP_USERNAME=#{node['acadock']['http_username']}"
  env << "HTTP_PASSWORD=#{node['acadock']['http_password']}"
end

if node['init_package'] == 'systemd'
  systemd_unit 'acadock-monitoring.service' do
    systemd_content = {
      'Unit' => {
        'Description' => 'Acadock - Docker monitoring tool',
        'After' => 'network.target docker.service',
      },
      'Service' => {
        'ExecStart' => File.join(acadock_dir, 'acadock-monitoring'),
        'Restart' => 'always',
        'RestartSec' => '30s',
        'Environment' => env,
      },
      'Install' => {
        'WantedBy' => 'multi-user.target',
      }
    }
    content systemd_content
    action :create
  end

  service 'acadock-monitoring' do
    provider Chef::Provider::Service::Systemd
    subscribes :restart, "remote_file[#{download_dest_path}]"
    action [:enable]
  end
else
  template '/etc/init/acadock-monitoring.conf' do
    source 'acadock-monitoring.conf.erb'
    mode 0o664
    variables({
      env: env,
      target: File.join(acadock_dir, 'acadock-monitoring'),
    })
    notifies :stop, 'service[acadock-monitoring]', :delayed
    notifies :start, 'service[acadock-monitoring]', :delayed
  end

  service 'acadock-monitoring' do
    provider Chef::Provider::Service::Upstart
    subscribes :restart, "remote_file[#{download_dest_path}]"
    action [:enable]
  end
end
