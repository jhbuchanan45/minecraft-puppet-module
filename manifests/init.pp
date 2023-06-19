# configures the minecraft server
#
# @param jdk_major_version
#  the major version of the jdk to install (eg 17)
#
# @param server_name
#  the name of the installed server. (eg 'real-server') Used as the directory name
class minecraft_server (
  String    $jdk_url,
  String    $jdk_archive_name,
  String    $server_name       = 'boltcraft',
  String    $server_url,
  Boolean   $forge_install       = true,
  String    $max_memory         = '4G',
  String    $min_memory         = '2G',
) {
  include 'archive'

  group { 'minecraft':
    ensure => present,
    name   => 'minecraft',
  }

  user { 'minecraft':
    ensure => present,
    name   => 'minecraft',
    groups => ['minecraft'],
  }

  file { "/opt/minecraft/${server_name}":
    ensure => directory,
    owner  => 'minecraft',
    group  => 'minecraft',
    mode   => '0754',
  }

  # $jdk_url_template = lookup('minecraft_server::jdk_url.aarch64')
  # $jdk_url = regsubst($jdk_url_template, '{{version}}', $jdk_major_version)

  notify { 'Details': message => "jdk_url: ${jdk_url}" }

  file { "/opt/minecraft/${server_name}/java":
    ensure => directory,
    owner  => 'minecraft',
    group  => 'minecraft',
    mode   => '0754',
  }

  archive { "/tmp/${jdk_archive_name}":
    ensure          => present,
    creates         => "/opt/minecraft/${server_name}/java/bin/java",
    source          => $jdk_url,
    extract         => true,
    extract_path    => "/opt/minecraft/${server_name}/java",
    extract_command => 'tar -xzf %s --strip-components=1',
    user            => 'minecraft',
    group           => 'minecraft',
  }

  archive { "/opt/minecraft/${server_name}/server_runner.jar":
    ensure  => present,
    creates => "/opt/minecraft/${server_name}/server_runner.jar",
    source  => $server_url,
    user    => 'minecraft',
    group   => 'minecraft',
  }

  systemd::manage_unit { "minecraft-${server_name}.service":
    unit_entry    => {
      'Description' => 'Minecraft Server',
      'After'       => 'network.target',
    },
    service_entry => {
      'Type'             => 'simple',
      'WorkingDirectory' => "/opt/minecraft/${server_name}",
      'User'             => 'minecraft',
      'Group'            => 'minecraft',
      'ExecStart'        => "/opt/minecraft/${server_name}/java/bin/java \
                              -server \
                              -Xms${min_memory} \
                              -Xmx${max_memory} \
                              -XX:+UnlockExperimentalVMOptions \
                              -XX:+AlwaysPreTouch \
                              -XX:+DisableExplicitGC \
                              -XX:+UseG1GC \
                              -Dsun.rmi.dgc.server.gcInterval=2147483646 \
                              -XX:G1NewSizePercent=20 \
                              -XX:MaxGCPauseMillis=50 \
                              -XX:G1HeapRegionSize=32M \
                              -XX:+ParallelRefProcEnabled \
                              -XX:+PerfDisableSharedMem \
                              -XX:+UseCompressedOops \
                              -XX:-UsePerfData \
                              -XX:ParallelGCThreads=4 \
                              -XX:MinHeapFreeRatio=5 \
                              -XX:MaxHeapFreeRatio=10 \
                              -jar server_runner.jar \
                              nogui",
      'Restart'          => 'always',
      'RestartSec'       => '5',
      'StandardOutput'   => 'journal',
      'StandardError'    => 'journal',
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
  }

  service { "minecraft-${server_name}":
    ensure => running,
  }
}
