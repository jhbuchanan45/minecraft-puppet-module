class minecraft_server::variants::forge inherits minecraft_server {
  $server_dir = "/opt/minecraft/${server_name}"

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

  if dir_empty('mods') {
    file { "${server_dir}/mods":
      ensure  => directory,
      purge   => true,
      recurse => true,
      mode    => '0655',
      owner   => 'minecraft',
      group   => 'minecraft',
      notify  => Service["minecraft-${server_name}"],
    }
  }

  archive { "/tmp/${server_name}/modpack.zip":
    ensure          => present,
    notify          => Service["minecraft-${server_name}"],
    source          => $modpack_url,
    extract         => true,
    extract_path    => "/opt/minecraft/${server_name}",
    user            => 'minecraft',
    group           => 'minecraft',
  }

  unless dir_empty('mods') {
    file { "${server_dir}/mods":
      ensure  => directory,
      source  => 'puppet:///modules/minecraft_server/mods',
      recurse => true,
      replace => true,
      purge   => true,
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
