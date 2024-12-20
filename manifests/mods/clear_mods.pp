class minecraft_server::mods::clear_mods inherits minecraft_server {
  $server_dir = "/opt/minecraft/${server_name}"

  file { "/tmp/${server_name}":
    ensure => directory,
    owner  => 'minecraft',
    group  => 'minecraft',
    mode   => '0754',
  }

  file { "/tmp/${server_name}/wipe_mods.rb":
    ensure  => file,
    content => "
    require 'fileutils'
    if (Dir.exists?('${server_dir}/mods'))
      FileUtils.remove_dir('${server_dir}/mods')
    end",
  }

  exec { 'clear mods folder':
    command => "/opt/puppetlabs/puppet/bin/ruby /tmp/${server_name}/wipe_mods.rb",
    require => File["/tmp/${server_name}/wipe_mods.rb"],
  }
}
