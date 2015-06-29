require 'json'
require 'ap'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'
require 'cgi'


@request_params = ActiveSupport::HashWithIndifferentAccess.new({
  :execution_list => [
    {
        :type =>  'file',
        :mode => '777',
        :source => {
            :type => 'in_payload',
            :content => "Hello WORLD!"
        },
        :target => {
            :path => "/Users/haris/test.pp"
        }
    },
    {
        :type    => 'syscall',
        :command => "more /Users/haris/test.pp",
        :timeout => 10
    },
  ]
})

def test_command_line
  transform_to_string = @request_params.to_json
  transform_to_string = CGI.escape(transform_to_string)
  result =  `dtk-action-agent '#{transform_to_string}'`
  print result
end

def test_inline
  require File.expand_path('../lib/logger', __FILE__)
  require File.expand_path('../lib/arbiter', __FILE__)
  require File.expand_path('../lib/commander', __FILE__)

  arbiter = DTK::Agent::Arbiter.new(@request_params)
  results = arbiter.run()
  ap results
end

test_command_line



