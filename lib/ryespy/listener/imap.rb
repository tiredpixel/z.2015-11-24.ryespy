require 'logger'
require 'redis'
require 'net/imap'


module Ryespy
  module Listener
    class IMAP
      
      def initialize(opts = {})
        @imap_config = {
          :host      => opts[:host],
          :port      => opts[:port],
          :ssl       => opts[:ssl],
          :username  => opts[:username],
          :password  => opts[:password],
        }
        
        @imap_mailboxes = opts[:mailboxes]
        
        @redis_ns_ryespy = opts[:redis_ns_ryespy]
        
        @notifiers = opts[:notifiers] || []
        @logger    = opts[:logger] || Logger.new(nil)
        
        @redis = Redis.current
        
        connect_imap
        
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
        @imap_mailboxes.each do |mailbox|
          @logger.debug { "mailbox:#{mailbox}" }
          
          redis_key = "#{@redis_ns_ryespy}#{@imap_config[:host]},#{@imap_config[:port]}:#{@imap_config[:username]}:#{mailbox}"
          
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
      
      private
      
      def connect_imap
        @imap = Net::IMAP.new(@imap_config[:host], {
          :port => @imap_config[:port],
          :ssl  => @imap_config[:ssl],
        })
        
        @imap.login(@imap_config[:username], @imap_config[:password])
      end
      
    end
  end
end
