require 'json'
require 'ap'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'
require 'cgi'


@request_params = ActiveSupport::HashWithIndifferentAccess.new(
  {
    :env_vars2 => { :HARIS => 'WORKS', :NESTO => 21 },
    :execution_list => [
      {
        :type    => 'syscall',
        #:command => 'bash ~/test_script.sh 2>&1',
        :command => "script -qfc 'JAVA_HOME=\"/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.75.x86_64\" HADOOP_HOME=\"/usr/lib/hadoop\" HADOOP_CONF_DIR=\"/etc/hadoop/conf/\" /usr/local/maven/bin/mvn verify -f /etc/puppet/modules/action_module/dtk/bigtop_tests/bigtop-tests/test-execution/smokes/hadoop/pom.xml'",
        :if      => 'echo works!'
      },
      {
        :type    => 'syscall',
        :command => '1date',
        :unless      => 'echo "Does not work!"'
      }],
    :positioning2 => [{
        :type => 'file',
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
        :type => 'file',
        :source => {
          :type => 'in_payload',
          :content => "Hello WORLD!"
        },
        :target => {
          :path => "/Users/haris/test-folder/site-stage-1-invocation-1.pp"
        }
      }]
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
  require File.expand_path('../lib/positioner', __FILE__)
  require File.expand_path('../lib/commander', __FILE__)

  arbiter = DTK::Agent::Arbiter.new(@request_params)
  results = arbiter.run()
  ap results
end

test_command_line



