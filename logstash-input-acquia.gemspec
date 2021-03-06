Gem::Specification.new do |s|
  s.name             = 'logstash-input-acquia'
  s.version          = File.read(File.join(File.dirname(__FILE__), 'VERSION')).strip
  s.licenses         = ['MIT']
  s.summary          = 'Logstash Input plugin that streams logs from Acquia Cloud'
  s.description      = 'This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program'
  s.authors          = ['Equiem']
  s.email            = 'sysadmin@equiem.com.au'
  s.homepage         = 'http://www.elastic.co/guide/en/logstash/current/index.html'

  s.files         = Dir['Gemfile', 'Rakefile', 'lib/logstash/inputs/acquia.rb', 'logstash-input-acquia.gemspec', '.ruby-version', 'VERSION', 'LICENSE']
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^spec/})
  s.require_paths = ['lib']

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core', '~> 1.5'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'stud'
  s.add_runtime_dependency 'acquia-cloud', '>= 0.2.1', '< 2.0.0'

  s.add_development_dependency 'logstash-devutils'
end
