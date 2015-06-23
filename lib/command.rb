module DTK
  module Agent

    ##
    # This is container for command as received from Node Agent

    class Command

      attr_accessor :command_type, :command, :if_success, :if_fail, :process, :child_task, :backtrace

      ##
      # command         - string to be run on system, e.g. ifconfig
      # type            - type of command e.g. syscall, ruby
      # if              - callback to be run if exit status is  = 0
      # unless          - callback to be run if exit status is != 0
      # stdout_redirect - redirect all output to stdout
      # child_task      - if it is spawned by another main task
      #

      STDOUT_REDIRECT = ' 2>&1'

      def initialize(value_hash)
        @command_type    = value_hash['type']
        @command         = value_hash['command']
        @stdout_redirect = !!value_hash['stdout_redirect']
        @if_success      = value_hash['if']
        @if_fail         = value_hash['unless']
        @spawned         = false
        @child_task      = value_hash['child_task'] || false
        @timeout         = (value_hash['timeout'] || 0).to_i

        @env_vars        = value_hash['env_vars']

        if @if_success && @if_fail
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
        ensure
          Commander.clear_environment_variables(@env_vars)
        end
      end

      ##
      # Checks if there is callaback present, callback beeing if/unless command
      #
      def callback_pending?
        return false if @spawned
        command_to_run = (self.exitstatus.to_i == 0) ? @if_success : @if_fail
        !!command_to_run
      end

      def is_positioning?
        'file'.eql?(@command_type)
      end


      ##
      # Creates Command object for callback, first check 'if' than 'unless'. There should be no both set so priority is given
      # to 'if' callback in case there are two
      #
      def spawn_callback_task
        callback_command = (self.exitstatus.to_i == 0) ? @if_success : @if_fail
        new_command = Command.new('type' => @command_type, 'command' => callback_command, 'child_task' => true)
        @spawned = true
        new_command
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
        self.process.out
      end

      def err
        return @error_message if @error_message
        self.process.err
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
