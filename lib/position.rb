require 'thread'
require 'git'
require 'fileutils'

module DTK
  module Agent
    class Position

      attr_accessor :position_file_info, :exitstatus, :started, :out, :err, :child_task, :backtrace, :owner, :mode

      def initialize(command_hash)
        source_info, target_info = command_hash['source'], command_hash['target']

        @type    = source_info['type'].to_sym
        @git_url = source_info['url']
        @branch  = source_info['ref'] || 'master'
        @content = source_info['content']

        @owner  = command_hash['owner']
        @mode   = command_hash['mode'].to_i if command_hash['mode']

        @env_vars = command_hash['env_vars']

        @target_path = target_info['path']

        @exited     = false
        @started    = false
        @exitstatus = 0
        @child_task = false
      end

      def start_task()
        @started = true
        prepare_path()

        Commander.set_environment_variables(@env_vars)

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
        ensure
          Commander.clear_environment_variables(@env_vars)
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
            Log.error("Positioner unable to clone provided url #{@git_url}")
            Log.error(e.message, e.backtrace)
          end
        else
          Log.warn("Positioner detected folder '#{@target_path}' skipping git clone")
        end

        @exited = true
      end

      def position_in_payload()
        # write to file
        file = File.open(@target_path, 'w')
        file.write(@content)

        if @owner
          begin
            FileUtils.chown(@owner, nil, file.path)
          rescue Exception => e
            Log.warn("Not able to set owner '#{@owner}', reason: " + e.message)
          end
        end

        if @mode
          begin
            FileUtils.chmod(@mode, file.path)
          rescue Exception => e
            Log.warn("Not able to set chmod permissions '#{@mode}', reason: " + e.message)
          end
        end

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