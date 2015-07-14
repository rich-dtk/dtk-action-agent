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
            :content => "Hello WORLD!\nnesto2"
        },
        :target => {
            :path => "/Users/haris/test.pp"
        }
    },
    {
        :type    => 'syscall',
        :command => "cat /Users/haris/test.pp | grep Hello",
        :timeout => 3,
        :stdout_redirect => true
    },
  ]
})

@request_params = ActiveSupport::HashWithIndifferentAccess.new({
    :execution_list => [
      {
        :env_vars => { :test_env => 'works', :test_env_second => 10 },
        :type            => 'syscall',
        :command         => "sleep 5",
        :unless          => 'wefwefwf',
        :stdout_redirect => true,
          :timeout         => 2
      }]
  })


# @request_params = {"execution_list"=> [{ "type"=>"syscall","command"=>"ls -l /usr/share/mcollective","stdout_redirect"=>true},{"type"=>"syscall","command"=>"ls /usr","stdout_redirect"=>true},{"type"=>"syscall","command"=>"rm -rf /tmp/test1","stdout_redirect"=>true},{"type"=>"syscall","command"=>"mkdir /tmp/test1","stdout_redirect"=>true},{"type"=>"syscall","command"=>"rm -rf /tmp/test2","stdout_redirect"=>true},{"type"=>"syscall","command"=>"mkdir /tmp/test2","stdout_redirect"=>true},{"type"=>"file","source"=>{"type"=>"in_payload","content"=>"testtesttest"},"target"=>{"path"=>"/tmp/test.txt"}},{"type"=>"syscall","command"=>"sudo apt-get update && sudo apt-get install -y postgresql-9.3 postgresql-contrib-9.3 postgresql-9.3-postgis-2.1 postgresql-client-9.3 inotify-tools && sudo rm -rf /var/lib/apt/lists/*","stdout_redirect"=>true},{"type"=>"file","source"=>{"type"=>"in_payload","content"=>"test\n"},"target"=>{"path"=>"/tmp/postgresql.conf"}},{"type"=>"syscall","command"=>"chown -R postgres:postgres /etc/postgresql/9.3/main/","stdout_redirect"=>true},{"type"=>"file","source"=>{"type"=>"in_payload","content"=>"echo \"POSTGRES.SH WORKS!!\"\n"},"target"=>{"path"=>"/var/lib/postgresql/postgres.sh"},"owner"=>"postgres","mode"=>"777"}]}

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



