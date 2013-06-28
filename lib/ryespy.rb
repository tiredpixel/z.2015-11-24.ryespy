require 'logger'

require_relative 'ryespy/version'
require_relative 'ryespy/config'
require_relative 'ryespy/redis_conn'

require_relative 'ryespy/listeners/imap'
require_relative 'ryespy/listeners/ftp'

require_relative 'ryespy/notifiers/sidekiq'


module Ryespy
  
  extend self
  
  def config
    @config ||= Ryespy::Config.new
  end
  
  def configure
    yield config
    
    Ryespy.logger.debug { "Configured #{Ryespy.config.to_s}" }
  end
  
  def logger
    unless @logger
      @logger = Logger.new($stdout)
      
      @logger.level = Logger.const_get(Ryespy.config.log_level)
    end
    
    @logger
  end
  
  def redis
    @redis ||= Ryespy::RedisConn.new(Ryespy.config.redis_url).redis
  end
  
  def notifiers
    unless @notifiers
      @notifiers = []
      
      Ryespy.config.notifiers[:sidekiq].each do |notifier_instance|
        @notifiers << Ryespy::Notifier::Sidekiq.new(notifier_instance)
      end
    end
    
    @notifiers
  end
  
end
