# configures the minecraft server
#
# @param jdk_major_version
#  the major version of the jdk to install (eg 17)
#
# @param server_name
#  the name of the installed server. (eg 'real-server') Used as the directory name
class minecraft_server (
  String    $jdk_major_version = '17',
  String    $server_name       = 'minecraft',
) {
  include 'archive'

  $jdk_url_template = lookup('minecraft_server::jdk_url.aarch64')
  $jdk_url = regsubst($jdk_url_template, '{{version}}', $jdk_major_version)

  notify { 'Details': message => "jdk_url: ${jdk_url}" }

  # archive { '/tmp/staging/master.zip':
  #   source       => 'https://github.com/voxpupuli/puppet-archive/archive/master.zip',
  #   extract      => true,
  #   extract_path => '/tmp/staging',
  #   creates      => '/tmp/staging/puppet-archive-master',
  #   cleanup      => false,
  # }
}
