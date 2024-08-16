class minecraft_server::variants::forge inherits minecraft_server {
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

  if $modpack_url {
    notify { 'modpack install':
      message => 'Installing modpack',
    }

    file { "/tmp/${server_name}/modpack":
      ensure  => directory,
      recurse => true,
      before  => Archive["/tmp/${server_name}/modpack.zip"],
      purge   => true,
      force   => true,
      owner   => 'minecraft',
      group   => 'minecraft',
      mode    => '0654',
    }

    archive { "/tmp/${server_name}/modpack.zip":
      ensure          => present,
      before          => Exec['copy modpack server files'],
      source          => $modpack_url,
      extract         => true,
      extract_path    => "/tmp/${server_name}/modpack",
      user            => 'minecraft',
      group           => 'minecraft',
      cleanup         => false,
    }

    file { "/tmp/${server_name}/copy_modpack.rb":
      ensure  => file,
      content => "
      require 'fileutils'

      cur_directory = '/tmp/${server_name}/modpack'
      p Dir.entries(cur_directory)
      while Dir.entries(cur_directory).size == 3
          subdirectory = Dir.entries(cur_directory).reject { |entry| entry == '.' || entry == '..' }.first
          p subdirectory
          cur_directory = File.join(cur_directory, subdirectory)
      end

      cur_directory = File.join(cur_directory, '.')
      
      FileUtils.cp_r(cur_directory, '${server_dir}')",
    }

    exec { 'copy modpack server files':
      require => [File["/tmp/${server_name}/copy_modpack.rb"], Exec['clear mods folder']],
      user    => 'minecraft',
      group   => 'minecraft',
      command => "/opt/puppetlabs/puppet/bin/ruby /tmp/${server_name}/copy_modpack.rb",
    }
  }

  notify { 'forge install':
    message => 'Installing forge server',
  }

  archive { "${server_dir}/forge_installer.jar":
    ensure  => present,
    creates => "${server_dir}/run.sh",
    source  => $server_url,
    user    => 'minecraft',
    group   => 'minecraft',
    notify  => Exec["install forge server ${server_name}"],
  }

  exec { "install forge server ${server_name}":
    command     => "${server_dir}/java/bin/java -jar forge_installer.jar --installServer",
    creates     => "${server_dir}/run.sh",
    cwd         => $server_dir,
    refreshonly => true,
    user        => 'minecraft',
    group       => 'minecraft',
    notify      => Service["minecraft-${server_name}"],
  }

  file { "${server_dir}/server_runner.sh":
    ensure  => file,
    content => "#!/usr/bin/env sh\nexport PATH=${server_dir}/java/bin:\$PATH\n${server_dir}/run.sh",
    mode    => '0755',
    owner   => 'minecraft',
    group   => 'minecraft',
    notify  => Service["minecraft-${server_name}"],
  }

  unless dir_empty('mods') {
    file { "${server_dir}/mods":
      ensure  => directory,
      # require => Exec['clear mods folder'],
      source  => 'puppet:///modules/minecraft_server/mods',
      recurse => remote,
      mode    => '0655',
      owner   => 'minecraft',
      group   => 'minecraft',
      notify  => Service["minecraft-${server_name}"],
  } }

  systemd::manage_unit { "minecraft-${server_name}.service":
    notify        => Service["minecraft-${server_name}"],
    unit_entry    => {
      'Description' => 'Minecraft Server',
      'After'       => 'network.target',
    },
    service_entry => {
      'Type'             => 'simple',
      'WorkingDirectory' => "/opt/minecraft/${server_name}",
      'User'             => 'minecraft',
      'Group'            => 'minecraft',
      'ExecStart'        => "${server_dir}/server_runner.sh",
      'Restart'          => 'always',
      'RestartSec'       => '5',
      'StandardOutput'   => 'journal',
      'StandardError'    => 'journal',
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
  }
}
