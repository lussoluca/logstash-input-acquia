# encoding: utf-8
require 'time'
require 'logstash/inputs/base'
require 'logstash/namespace'
require 'stud/interval'
require 'acquia/cloud'

class LogStash::Inputs::Acquia < LogStash::Inputs::Base
  config_name 'acquia'

  default :codec, 'plain'
  VERSION = File.read(File.join(File.dirname(__FILE__), '../../../VERSION')).strip

  config :username, :validate => :string, :required => true
  config :api_key, :validate => :string, :required => true
  config :site, :validate => :string, :required => true
  config :environments, :validate => :array, :default => ['prod']
  config :types, :validate => :array, :default => ['drupal-watchdog', 'php-error']

  public
  def register
    @cloud = ::Acquia::Cloud.new(:credentials => "#{@username}:#{@api_key}")
    @site = @cloud.site(@site)
    @streams = {}
    @environments.each do |env|
      @logger.info "Opening log stream for #{env}."
      stream = @site.environment(env).logstream
      @types.each do |type|
        stream.enable_type type
      end
      stream.connect
      @streams[env] = stream
    end
  end

  def run(queue)
    Stud.interval(1) do
      @streams.each do |env, stream|
        stream.each_log do |log|
          # p log
          event = generate_event(env, log)
          decorate(event)
          queue << event
        end
      end
    end
  end

  def stop
    @logger.info 'Closing log streams.'
    @streams.each do |stream|
      stream.close
    end
  end

  private
  def generate_event(env, log)
    # Remove useless API cruft.
    log.delete 'cmd'

    # Save the environment this message is coming from.
    log['acquia'] = {
        'site' => @site.name,
        'environment' => env,
    }

    # Rename some of Acquia's parameters to more relevant Logstash names.
    log['host'] = log.delete('server')
    log['message'] = log.delete('text')

    # Trim off duplicated request id if Acquia has already provided it
    # separately.
    if log['request_id']
      matches = log['message'].match %r{\s+request_id="#{log['request_id']}"\s+$}
      if matches
        log['message'] = log['message'][0, log['message'].length - matches[0].length]
      end
    end

    timestamp = log.delete('disp_time')
    if timestamp
      begin
        log['@timestamp'] = Time.parse(timestamp + ' +0000').iso8601
      rescue ArgumentError
        # Not a valid timestamp. Oh well. Clean up, just in case.
        log.delete '@timestamp'
      end
    end

    LogStash::Event.new(log)
  end
end
