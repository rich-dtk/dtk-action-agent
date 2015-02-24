require 'thread'
require 'git'
require 'fileutils'

module DTK
  module Agent
    class Positioner

      attr_accessor :position_file_info

      def initialize(*position_file_info)
        @position_file_info = position_file_info.flatten.compact
      end

      def run()
        @position_file_info.each do |pfi|
          case pfi['source']['type'].to_sym
          when :git
            position_git(pfi)
          when :in_payload
            position_in_payload(pfi)
          end
        end
      end

    private

      def position_git(position_info)
        folder_path = prepare_path(position_info)
        git_url     = position_info['source']['url']
        git_branch  = position_info['source']['ref']

        unless File.directory?(folder_path)
          begin
            g_repo = Git.clone("#{git_url}", '', :path => folder_path, :branch => git_branch)
            Log.info("Positioner successfully cloned git repository '#{git_url}@#{git_branch}' to location '#{folder_path}'")
          rescue Exception => e
            Log.error("Positioner unable to clone #{git_url}")
            Log.error(e.message)
          end
        else
          Log.warn("Positioner detected folder '#{folder_path}' skipping git clone")
        end
      end

      def position_in_payload(position_info)
        file_path    = prepare_path(position_info)
        file_content = position_info['source']['content']
        # write to file
        File.open(file_path, 'w') { |file| file.write(file_content) }
        Log.info("Positioner successfully created 'IN_PAYLOAD' file '#{file_path}'")
      end

      def prepare_path(position_info)
        path = position_info['target']['path']

        # create necessery dir structure
        FileUtils.mkdir_p(File.dirname(path))

        path
      end

    end
  end
end