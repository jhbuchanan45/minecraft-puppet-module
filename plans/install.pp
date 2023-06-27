# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary A plan created with bolt plan new.
# @param targets The targets to run on.
plan minecraft_server::install (
  TargetSpec $targets = 'localhost'
) {
  out::message('Hello from minecraft_server::install')

  apply_prep($targets)

  $out = apply($targets, _description => 'minecraft_server_install') {
    class { 'minecraft_server' :
      jdk_url          => 'https://download.oracle.com/java/17/archive/jdk-17.0.6_linux-aarch64_bin.tar.gz',
      jdk_archive_name => 'jdk-17.0.6_linux-aarch64_bin.tar.gz',
      server_name      => 'boltcraft',
      server_url       => 'https://maven.minecraftforge.net/net/minecraftforge/forge/1.19.2-43.2.14/forge-1.19.2-43.2.14-installer.jar',
      forge_install    => true,
      min_memory       => '6G',
      max_memory       => '12G',
    }
  }

  out::message($out)

  # apply($targets, _description => 'java_install') {
  #   include java

  #   java::download { 'jdk16' :
  #     version => '16',
  #   }
  # }

  # apply($target, _description => 'java_install') {
  #   include java

  #   class { 'java' :
  #     version => '16',
  #     arch    => 'aarch64',
  #   }
  # }
  $command_result = run_command('whoami', $targets)
  return $command_result
}
