require 'thread'
require 'git'
require 'fileutils'

module DTK
  module Agent
    class Position

      attr_accessor :position_file_info, :exitstatus, :started, :out, :err, :child_task

      def initialize(command_hash)
        source_info, target_info = command_hash['source'], command_hash['target']

        @type    = source_info['type'].to_sym
        @git_url = source_info['url']
        @branch  = source_info['ref'] || 'master'
        @content = source_info['content']

        @target_path = target_info['path']

        @exited     = false
        @started    = false
        @exitstatus = 0
        @child_task = false
      end

      def start_task()
        @started = true
        prepare_path()

        begin
          case @type
          when :git
            position_git()
          when :in_payload
            position_in_payload()
          end
        rescue Exception => e
          cleanup_path()
          raise e
        end
      end

      def exited?
        @exited
      end

      #
      # This are not standard commands and as such we are ignoring their output
      #
      def started?
        @started
      end

      def spawn_callback_task
        raise "Callback task is not supported for positioner"
      end

      def callback_pending?
        # not supported at the moment
        false
      end

      def to_s
        :git.eql?(@type) ? "git clone #{@git_url}:#{@branch} > #{@target_path}" : "create #{@target_path} with provided content"
      end

    private

      def position_git()
        unless File.directory?(@target_path)
          begin
            g_repo = Git.clone("#{@git_url}", '', :path => @target_path, :branch => @branch)
            Log.info("Positioner successfully cloned git repository '#{@git_url}@#{@branch}' to location '#{@target_path}'")
          rescue Exception => e
            cleanup_path()
            @exitstatus = 1
            Log.error("Positioner unable to clone #{@git_url}")
            Log.error(e.message)
          end
        else
          Log.warn("Positioner detected folder '#{@target_path}' skipping git clone")
        end

        @exited = true
      end

      def position_in_payload(position_info)
        # write to file
        File.open(@target_path, 'w') { |file| file.write(@content) }
        Log.info("Positioner successfully created 'IN_PAYLOAD' file '#{@target_path}'")
        @exited = true
      end

      def prepare_path()
        # create necessery dir structure
        FileUtils.mkdir_p(File.dirname(@target_path))

        @target_path
      end

      def cleanup_path()
        FileUtils.rm_rf(@target_path)
      end

    end
  end
end