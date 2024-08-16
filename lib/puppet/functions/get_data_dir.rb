require 'fileutils'

Puppet::Functions.create_function(:get_data_dir) do
    dispatch :get_data_dir do
        param 'String', :directory
    end

    def get_data_dir(directory)
        cur_directory = directory
        while Dir.entries(directory).size == 3
            subdirectory = Dir.entries(cur_directory).reject { |entry| entry == '.' || entry == '..' }.first
            cur_directory = File.join(cur_directory, subdirectory)
        end

        return cur_directory
    end
end
