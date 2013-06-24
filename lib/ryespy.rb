require 'logger'

require_relative 'ryespy/version'
require_relative 'ryespy/config'
require_relative 'ryespy/redis_conn'

require_relative 'ryespy/listeners/imap'


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
  
  def check_listener
    redis_prefix = "#{Ryespy.config.redis_ns_ryespy}#{Ryespy.config.listener}:"
    
    Ryespy::RedisConn.new do |redis|
      Ryespy.send("check_#{Ryespy.config.listener}", redis, redis_prefix)
    end
  end
  
  def check_imap(redis, redis_prefix)
    redis_prefix += "#{Ryespy.config.imap_host},#{Ryespy.config.imap_port}:#{Ryespy.config.imap_username}:"
    
    Ryespy::Listener::IMAP.new do |listener|
      Ryespy.config.imap_mailboxes.each do |mailbox|
        Ryespy.logger.debug { "mailbox:#{mailbox}" }
        
        redis_key = redis_prefix + "#{mailbox}"
        
        Ryespy.logger.debug { "redis_key:#{redis_key}" }
        
        new_items = listener.check({
          :mailbox       => mailbox,
          :last_seen_uid => redis.get(redis_key).to_i,
        })
        
        Ryespy.logger.debug { "new_items:#{new_items}" }
        
        new_items.each do |uid|
          redis.set(redis_key, uid)
          
          # TODO: Notify.
        end
        
        Ryespy.logger.info { "#{mailbox} has #{new_items.count} new emails" }
      end
    end
  end
  
end
