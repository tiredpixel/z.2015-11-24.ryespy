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
  
  def notifiers
    unless @notifiers
      @notifiers = []
      
      Ryespy.config.notifiers[:sidekiq].each do |notifier_instance|
        @notifiers << Ryespy::Notifier::Sidekiq.new(notifier_instance)
      end
    end
    
    @notifiers
  end
  
  def check_listener
    begin
      Ryespy.send("check_#{Ryespy.config.listener}")
    ensure
      notifiers.each { |n| n.close }
    end
  end
  
  def check_imap
    Ryespy::RedisConn.new(Ryespy.config.redis_url) do |redis|
      Ryespy::Listener::IMAP.new do |listener|
        Ryespy.config.imap_mailboxes.each do |mailbox|
          Ryespy.logger.debug { "mailbox:#{mailbox}" }
          
          redis_key = "#{Ryespy.config.redis_prefix_ryespy}#{Ryespy.config.imap_host},#{Ryespy.config.imap_port}:#{Ryespy.config.imap_username}:#{mailbox}"
          
          Ryespy.logger.debug { "redis_key:#{redis_key}" }
          
          new_items = listener.check({
            :mailbox       => mailbox,
            :last_seen_uid => redis.get(redis_key).to_i,
          })
          
          Ryespy.logger.debug { "new_items:#{new_items}" }
          
          new_items.each do |uid|
            redis.set(redis_key, uid)
            
            notifiers.each { |n| n.notify('RyespyIMAPJob', [mailbox, uid]) }
          end
          
          Ryespy.logger.info { "#{mailbox} has #{new_items.count} new emails" }
        end
      end
    end
  end
  
  def check_ftp
    Ryespy::RedisConn.new(Ryespy.config.redis_url) do |redis|
      Ryespy::Listener::FTP.new do |listener|
        Ryespy.config.ftp_dirs.each do |dir|
          Ryespy.logger.debug { "dir:#{dir}" }
          
          redis_key = "#{Ryespy.config.redis_prefix_ryespy}#{Ryespy.config.ftp_host}:#{Ryespy.config.ftp_username}:#{dir}"
          
          Ryespy.logger.debug { "redis_key:#{redis_key}" }
          
          new_items = listener.check({
            :dir        => dir,
            :seen_files => redis.hgetall(redis_key),
          })
          
          Ryespy.logger.debug { "new_items:#{new_items}" }
          
          new_items.each do |filename, checksum|
            redis.hset(redis_key, filename, checksum)
            
            notifiers.each { |n| n.notify('RyespyFTPJob', [dir, filename]) }
          end
          
          Ryespy.logger.info { "#{dir} has #{new_items.count} new files" }
        end
      end
    end
  end
  
end
