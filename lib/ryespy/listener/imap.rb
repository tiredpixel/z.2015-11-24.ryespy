require 'logger'
require 'redis'
require 'net/imap'


module Ryespy
  module Listener
    class IMAP
      
      def initialize(opts = {})
        @config    = opts[:config] || Config.new
        @notifiers = opts[:notifiers] || []
        @logger    = opts[:logger] || Logger.new(nil)
        
        @redis = Redis.current
        
        @imap = Net::IMAP.new(@config.imap_host, {
          :port => @config.imap_port,
          :ssl  => @config.imap_ssl,
        })
        
        @imap.login(@config.imap_username, @config.imap_password)
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @imap.disconnect
      end
      
      def check(params)
        @imap.select(params[:mailbox])
        
        uids = @imap.uid_search("#{params[:last_seen_uid] + 1}:*")
        
        uids.find_all { |uid| uid > params[:last_seen_uid] } # IMAP search gets fun with edge cases
      end
      
      def check_all
        @config.imap_mailboxes.each do |mailbox|
          @logger.debug { "mailbox:#{mailbox}" }
          
          redis_key = "#{@config.redis_prefix_ryespy}#{@config.imap_host},#{@config.imap_port}:#{@config.imap_username}:#{mailbox}"
          
          @logger.debug { "redis_key:#{redis_key}" }
          
          begin
            new_items = check({
              :mailbox       => mailbox,
              :last_seen_uid => @redis.get(redis_key).to_i,
            })
          rescue Net::IMAP::Error => e
            @logger.error { e.to_s }
          end
          
          @logger.debug { "new_items:#{new_items}" }
          
          new_items.each do |uid|
            @redis.set(redis_key, uid)
            
            @notifiers.each { |n| n.notify('RyespyIMAPJob', [mailbox, uid]) }
          end
          
          @logger.info { "#{mailbox} has #{new_items.count} new emails" }
        end
      end
      
    end
  end
end
