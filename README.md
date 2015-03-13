## DTK Action Agent

### Description

DTK action agent is system gem design to run system task asynchronously on host system. Most if it relies on `posix-spawn` gem for parallel execution.

#### Requirements

* Ruby 1.9.3+

##### Installation

As any gem we need to run:

	gem build dtk-action-agent.gemspec

	gem install dtk-action-agent*.gem

##### Example

Example of instruction hash:

	example = {
		:env_vars => { :test_env => 'works', :test_env_second => 10 },
    	:execution_list => [
        {
        	:type            => 'syscall',
        	:command         => "date",
        	:if              => 'echo works!',
        	:redirect_stdout => true
      	},
      	{
        	:type    => 'syscall',
        	:command => '1date',
        	:unless      => 'echo "Does not work!"'
       }],
    	:positioning => [
    	{
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
        	:target =>
        	{
          		:path => "/Users/haris/test-folder/site-stage-1-invocation-1.pp"
        	}
      }]
	}

Hash needs to be encoded and sent as JSON.

	transform_to_string = example.to_json
  	transform_to_string = CGI.escape(transform_to_string)
 	result = `dtk-action-agent '#{transform_to_string}'`

Have fun!