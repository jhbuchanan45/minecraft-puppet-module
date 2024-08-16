# Define a custom function to check if a dir is empty in the module's files directory
# Usage: dir_empty('mydir')
# Returns: true if the dir is empty, false otherwise
# Note: The dir path is relative to the module's dir directory
# Example: dir_exists('mydir') => true if the dir is empty at 'modules/minecraft_server/files/mydir'

Puppet::Functions.create_function(:dir_empty) do
  dispatch :dir_empty do
    required_param 'String', :dirname
  end

  def dir_empty(dirname)
    module_dir = Puppet::Module.find('minecraft_server').path
    dir_path = File.join(module_dir, 'files', dirname)

    return Dir.empty?(dir_path)
  end
end
