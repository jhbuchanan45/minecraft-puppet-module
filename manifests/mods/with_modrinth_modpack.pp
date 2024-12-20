class minecraft_server::mods::sync_mods inherits minecraft_server {
  $server_dir = "/opt/minecraft/${server_name}"

  notify { 'modrinth modpack install':
    message => 'Installing modrinth modpack',
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
