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
  config :interval, :validate => :number, :default => 10
  config :debug, :validate => :boolean, :default => false

  public
  def register
    @cloud = ::Acquia::Cloud.new(:credentials => "#{@username}:#{@api_key}")
    @acsite = @cloud.site(@site)
  end

  def run(queue)
    @streams = {}
    @environments.each do |env|
      @streams[env] = get_stream(env)
    end
    Stud.interval(@interval) do
      @streams.each do |env, stream|
        begin
          stream.each_log do |log|
            # p log
            event = generate_event(env, log)
            decorate(event)
            queue << event
          end
        rescue Errno::EPIPE
          @logger.warn("Detected a broken pipe for #{env} on #{@site}, reconnecting.")
          @streams[env] = get_stream(env)
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
  def get_stream(env)
    @logger.info "Opening log stream for #{env}."
    stream = @acsite.environment(env).logstream
    @types.each do |type|
      stream.enable_type type
    end
    stream.keepalive_duration = @interval * 2
    stream.debug if @debug
    stream.connect
    stream
  end

  def generate_event(env, log)
    # Remove useless API cruft.
    log.delete 'cmd'

    # Save the environment this message is coming from.
    log['acquia'] = {
        'site' => @acsite.name,
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
