def current_version
  File.read('VERSION').strip
end

def current_gems
  Dir["pkg/logstash-input-acquia-#{current_version}.gem"]
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
      sh *%W{git tag #{current_version}}
      sh *%W{git push origin tag #{current_version}}
    end
  end
end
