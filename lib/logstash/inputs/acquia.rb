# encoding: utf-8
require 'logstash/inputs/base'
require 'logstash/namespace'
require 'stud/interval'
require 'acquia/cloud'

class LogStash::Inputs::Acquia < LogStash::Inputs::Base
  config_name 'acquia'

  default :codec, 'plain'

  config :environments, :validate =>

  public
  def register
    
  end

  def run(queue)
    Stud.interval(1) do

    end
  end

  def stop

  end
end
