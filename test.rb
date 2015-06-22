require 'json'
require 'ap'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'
require 'cgi'


@request_params2 = ActiveSupport::HashWithIndifferentAccess.new({
  :execution_list => [
    {
        :env_vars => { :test_env2 => 'works32', :test_env_second2 => 10 },
        :type            => 'syscall',
        :command         => "sleep 4",
        :if              => 'echo works!',
        :stdout_redirect => true,
        :timeout => 0
    },
    {
        :env_vars => { :test_env2 => 'works32', :test_env_second2 => 10 },
        :type            => 'syscall',
        :command         => "sleep 4",
        :if              => 'echo works!',
        :stdout_redirect => true,
        :timeout => 1
    },
    {
        :type => 'file',
        :env_vars => { :test_env => 'works', :test_env_second => 10 },
        :source => {
           :type => 'git',
           :url => "git@github.com:rich-reactor8/dtk-client.git",
           :ref => "tenant1"
        },
        :target => {
          :path => "/Users/haris/foo-test"
        },
    },
   {
        :type    => 'syscall',
        :command => '1date',
        :unless      => 'echo "Does not work!"'
   }]

})

@request_params = ActiveSupport::HashWithIndifferentAccess.new({
 :execution_list => [
         {
                        :type => "syscall",
                     :command => "ls /tmp",
             :stdout_redirect => true
         },
         {
                        :type => "syscall",
                     :command => "ls /usr",
             :stdout_redirect => true
         },
         {
               :type => "file",
             :source => {
                    :type => "in_payload",
                 :content => "Hello WORLD!"
             },
             :target => {
                 :path => "/tmp/works.pp"
             }
         },
         {
               :type => "file",
             :source => {
                    :type => "in_payload",
                 :content => "Hello WORLD!"
             },
             :target => {
                 :path => "/tmp/baba.pp"
             }
         }
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



