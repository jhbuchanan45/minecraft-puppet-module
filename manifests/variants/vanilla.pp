class minecraft_server::variants::vanilla inherits minecraft_server {
  $server_dir = "/opt/minecraft/${server_name}"

  notify { 'vanilla install':
    message => 'Installing vanilla server',
  }

  archive { "${server_dir}/server_runner.jar":
    ensure  => present,
    notify  => Service["minecraft-${server_name}"],
    creates => "${server_dir}/server_runner.jar",
    source  => $server_url,
    user    => 'minecraft',
    group   => 'minecraft',
  }

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
      'ExecStart'        => "${server_dir}/java/bin/java \
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
}
