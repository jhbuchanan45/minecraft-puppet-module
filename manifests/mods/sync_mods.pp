class minecraft_server::variants::sync_mods inherits minecraft_server {
  $server_dir = "/opt/minecraft/${server_name}"

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
}
