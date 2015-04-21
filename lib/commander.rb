require File.expand_path('../command', __FILE__)
require File.expand_path('../position', __FILE__)


module DTK
  module Agent
    class Commander

      PARALLEL_EXECUTION = ENV['DTK_ACTION_AGENT_PARALLEL_EXEC'] || false

      def initialize(execution_list)
        @command_tasks  = execution_list.collect do |command|
          if (command['type'].eql?('file'))
            Position.new(command)
          else
            Command.new(command)
          end
        end
      end

      def run
        if PARALLEL_EXECUTION
          parallel_run()
        else
          sequential_run()
        end
      end

      def sequential_run
        @command_tasks.each do |command_task|
          command_task.start_task

          loop do
            if command_task.exited?
              Log.debug("Command '#{command_task}' finished, with status #{command_task.exitstatus}")

              # exit if there is an error
              return nil if (command_task.exitstatus.to_i > 0)

              # if there is a callback start it
              spawn_callback_task(command_task) if command_task.callback_pending?

              break
            end

            sleep(1)
          end

        end
      end

      def parallel_run
        @command_tasks.each do |command_task|
          command_task.start_task
        end

        loop do
          all_finished = true
          sleep(1)

          # we check status of all tasks
          # (Usually is not good practice to change array/map you are iterating but this seems as cleanest solutions)
          @command_tasks.each do |command_task|
            # is task finished
            if command_task.exited?
              Log.debug("Command '#{command_task}' finished, with status #{command_task.exitstatus}")

              # if there is a callback start it
              if command_task.callback_pending?
                spawn_callback_task(command_task, true)
                # new task added we need to check again
                all_finished = false
              end
            else
              # we are not ready yet, some tasks need to finish
              all_finished = false
            end
          end

          break if all_finished
        end
      end

      def spawn_callback_task(command_task, start_task = false)
        new_command_task = command_task.spawn_callback_task
        new_command_task.start_task if start_task
        @command_tasks << new_command_task
        Log.debug("Command '#{new_command_task}' spawned as callback")
      end

      def results
        res = @command_tasks.collect do |command_task|
          next unless command_task.started?
          {
            :status      => command_task.exitstatus,
            :stdout      => command_task.out,
            :stderr      => command_task.err,
            :description => command_task.to_s,
            :child_task  => command_task.child_task
          }
        end

        res.compact
      end

    private

      def self.clear_environment_variables(env_vars_hash)
        return unless env_vars_hash
        env_vars_hash.keys.each do |k|
          ENV.delete(k)
          Log.debug("Environment variable cleared (#{k})")
        end
      end

      ##
      # Sets environmental variables
      def self.set_environment_variables(env_vars_hash)
        return unless env_vars_hash
        env_vars_hash.each do |k, v|
          ENV[k] = v.to_s.strip
          Log.debug("Environment variable set (#{k}: #{v})")
        end
      end

    end

  end
end