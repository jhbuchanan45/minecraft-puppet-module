# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary A plan created with bolt plan new.
# @param targets The targets to run on.
plan minecraft_server::stop (
  TargetSpec $targets = 'localhost'
) {
  out::message('Hello from minecraft_server::stop')

  apply_prep($targets)

  $out = apply($targets, _description => 'minecraft_server_stop') {
    service { "minecraft-${lookup('minecraft_server::server_name')}":
      ensure => stopped,
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
