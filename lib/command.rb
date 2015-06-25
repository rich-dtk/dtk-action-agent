module DTK
  module Agent

    ##
    # This is container for command as received from Node Agent

    class Command

      attr_accessor :command_type, :command, :process, :backtrace

      ##
      # command         - string to be run on system, e.g. ifconfig
      # type            - type of command e.g. syscall, ruby
      # if              - callback to be run if exit status is  = 0
      # unless          - callback to be run if exit status is != 0
      # stdout_redirect - redirect all output to stdout
      #

      STDOUT_REDIRECT = ' 2>&1'

      def initialize(value_hash)
        @command_type    = value_hash['type']
        @command         = value_hash['command']
        @stdout_redirect = !!value_hash['stdout_redirect']

        @if              = value_hash['if']
        @unless          = value_hash['unless']

        @timeout         = (value_hash['timeout'] || 0).to_i

        @env_vars        = value_hash['env_vars']

        if @if && @unless
          Log.warn "Unexpected case, both if/unless conditions have been set for command #{@command}(#{@command_type})"
        end
      end

      ##
      # Creates Posix Spawn of given process
      #
      def start_task
        begin
          Commander.set_environment_variables(@env_vars)
          @process = POSIX::Spawn::Child.new(formulate_command, :timeout => @timeout)
          Log.debug("Command started: '#{self.to_s}'")
        rescue POSIX::Spawn::TimeoutExceeded => e
          @error_message = "Timeout (#{@timeout} sec) for this action has been exceeded"
        rescue Exception => e
          @error_message = e.message
          @backtrace = e.backtrace
          Log.error(@error_message, @backtrace)
        ensure
          Commander.clear_environment_variables(@env_vars)
        end
      end

      ##
      # Checks if there is callaback present, callback beeing if/unless command
      #
      def callback_pending?
        @if || @unless
      end

      def is_positioning?
        'file'.eql?(@command_type)
      end

      ##
      # Returns true/false based on condition data and result of process
      #
      def run_condition_task
        condition_command   = @if
        condition_command ||= @unless

        begin
          condition_process = POSIX::Spawn::Child.new(condition_command, :timeout => @timeout)
        rescue Exception => e
          Log.warn("Condition command '#{condition_command}' ran into an exception, message: #{e.message}")
          # return true if unless condition was used
          return @unless ? true : false
        end

        while (!condition_process.status.exited?) do
          sleep(1)
        end

        return condition_process.status.exitstatus > 0 ? false : true if @if
        return condition_process.status.exitstatus > 0 ? true  : false if @unless
      end

      def exited?
        return true if @error_message
        self.process.status.exited?
      end

      def exitstatus
        return 1 if @error_message
        self.process.status.exitstatus
      end

      def out
        return '' if @error_message
        self.process.out.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '')
      end

      def err
        return @error_message if @error_message
        self.process.err.encode!('UTF-8', :invalid => :replace, :undef => :replace, :replace => '')
      end

      def started?
        return true if @error_message
        !!self.process
      end

      def to_s
        "#{formulate_command} (#{command_type})"
      end

    private

      #
      # Based on stdout-redirect flag
      #
      def formulate_command
        @stdout_redirect ? "#{@command} #{STDOUT_REDIRECT}" : @command
      end

    end
  end
  end
