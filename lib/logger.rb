require 'logger'
require 'singleton'

module DTK
  module Agent
    class Log
      include Singleton

      attr_accessor :logger, :error_msgs

      LOG_TO_CONSOLE = false
      LOG_TO_FILE    = '/var/log/action-agent.log'
      # LOG_TO_FILE    = '/Users/haris/test.log'

      def initialize
        # @logger = Logger.new(File.new(LOG_TO_FILE,'w'))
        @error_msgs =[]
      end

      def self.execution_errors()
        self.instance.error_msgs
      end

      def self.debug(msg)
        # self.instance.logger.debug(msg)
        ap "debug: #{msg}" if LOG_TO_CONSOLE
      end

      def self.info(msg)
        # self.instance.logger.info(msg)
        ap "info: #{msg}" if LOG_TO_CONSOLE
      end

      def self.warn(msg, backtrace = nil)
        # self.instance.logger.warn(msg)
        ap "warn: #{msg}" if LOG_TO_CONSOLE
        self.instance.error_msgs <<  :message => msg, :backtrace => backtrace }
      end

      def self.error(msg, backtrace = nil)
        # self.instance.logger.error(msg)
        ap "error: #{msg}" if LOG_TO_CONSOLE
        self.instance.error_msgs << { :message => msg, :backtrace => backtrace }
      end

    end
  end
end
