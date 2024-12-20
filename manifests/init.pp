# configures the minecraft server
# @param server_name
#  the name of the installed server. (eg 'real-server') Used as the directory name
class minecraft_server (
  String    $jdk_url,
  String    $jdk_archive_name,
  Hash      $server_properties,
  String    $server_url,
  String    $server_name       = 'boltcraft',
  Boolean   $forge_install       = true,
  Boolean   $modrinth_modpack_install = false,
  Boolean   $strip_modpack_wrapper = false,
  Boolean   $sync_mods = false,
  String    $modpack_url,
  String    $max_memory         = '4G',
  String    $min_memory         = '2G',
  Tuple     $op_users = undef ,

) {
  include 'archive'

  $server_dir = "/opt/minecraft/${server_name}"

  group { 'minecraft':
    ensure => present,
    name   => 'minecraft',
  }

  user { 'minecraft':
    ensure => present,
    name   => 'minecraft',
    groups => ['minecraft'],
  }

  file { '/opt/minecraft':
    ensure => directory,
    owner  => 'minecraft',
    group  => 'minecraft',
    mode   => '0754',
  }

  file { $server_dir:
    ensure  => directory,
    recurse => true,
    owner   => 'minecraft',
    group   => 'minecraft',
    mode    => '0754',
  }

  # $jdk_url_template = lookup('minecraft_server::jdk_url.aarch64')
  # $jdk_url = regsubst($jdk_url_template, '{{version}}', $jdk_major_version)

  notify { 'Details': message => "jdk_url: ${jdk_url}" }

  file { "${server_dir}/java":
    ensure => directory,
    notify => Service["minecraft-${server_name}"],
    owner  => 'minecraft',
    group  => 'minecraft',
    mode   => '0754',
  }

  archive { "/tmp/${jdk_archive_name}":
    ensure          => present,
    notify          => Service["minecraft-${server_name}"],
    creates         => "/opt/minecraft/${server_name}/java/bin/java",
    source          => $jdk_url,
    extract         => true,
    extract_path    => "/opt/minecraft/${server_name}/java",
    extract_command => 'tar -xzf %s --strip-components=1',
    user            => 'minecraft',
    group           => 'minecraft',
  }

  file { "${server_dir}/eula.txt":
    ensure  => file,
    content => "eula=true\n",
    owner   => 'minecraft',
    group   => 'minecraft',
    mode    => '0644',
  }

  $defaults = {
    'path' => "${server_dir}/server.properties",
    'notify'=> Service["minecraft-${server_name}"],
  }
  $server_properties_hash = { '' => $server_properties }
  inifile::create_ini_settings($server_properties_hash, $defaults)

  file { "${server_dir}/ops.json":
    ensure  => file,
    content => to_json($op_users),
    owner   => 'minecraft',
    group   => 'minecraft',
    mode    => '0644',
  }

  if ($modpack_url or $sync_mods) {
    contain minecraft_server::mods::clear_mods
  }

  if ($modpack_url) {
    contain minecraft_server::mods::sync_mods
  }

  unless ($forge_install == true) {
    contain minecraft_server::variants::vanilla
  } else {
    contain minecraft_server::variants::forge
  }

  if ($sync_mods) {
    contain minecraft_server::mods::sync_mods
  }

  systemd::manage_unit { "minecraft-${server_name}-restart.service":
    unit_entry    => {
      'Description' => 'Restart minecraft server',
    },
    service_entry => {
      'Type'      => 'oneshot',
      'ExecStart' => "/bin/systemctl try-restart minecraft-${server_name}.service",
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
  }

  systemd::manage_unit { "minecraft-${server_name}-restart.timer":
    unit_entry    => {
      'Description' => 'Timer to restart minecraft server',
    },
    timer_entry   => {
      'Unit'       => "minecraft-${server_name}-restart.service",
      'OnCalendar' => '6',
      'Persistent' => true,
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
  }

  service { "minecraft-${server_name}":
    ensure => running,
  }
}
