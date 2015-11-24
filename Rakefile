$:.push File.join(File.dirname(__FILE__), 'lib')

require 'logstash/inputs/acquia/version'

def current_gems
  Dir["pkg/logstash-input-acquia-*.gem"]
end

namespace :gem do
  desc 'Build gem'
  task :build do
    mkdir 'pkg' unless File.exist? 'pkg'
    sh *%w{gem build logstash-input-acquia.gemspec}
    Dir['*.gem'].each do |gem|
      mv gem, "pkg/#{gem}"
    end
  end

  desc 'Deploy gems to rubygems'
  task :deploy => ['gem:build'] do
    current_gems.each do |gem|
      sh *%W{gem push #{gem}}
    end
    if File.exist? '.git'
      sh *%W{git tag #{LogStash::Inputs::Acquia::VERSION}}
      sh *%W{git push origin tag #{LogStash::Inputs::Acquia::VERSION}}
    end
  end
end
