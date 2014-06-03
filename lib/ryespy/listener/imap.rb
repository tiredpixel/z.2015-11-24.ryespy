require 'net/imap'

require_relative 'base'


module Ryespy
  module Listener
    class IMAP < Base
      
      REDIS_KEY_PREFIX  = 'imap'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyIMAPJob'.freeze
      
      def initialize(opts = {})
        @imap_config = {
          :host      => opts[:host],
          :port      => opts[:port],
          :ssl       => opts[:ssl],
          :username  => opts[:username],
          :password  => opts[:password],
        }
        
        super(opts)
      end
      
      def close
        @imap.disconnect
      end
      
      def check(mailbox)
        @logger.debug { "mailbox: #{mailbox}" }
        
        @logger.debug { "redis_key: #{redis_key(mailbox)}" }
        
        last_seen_uid = @redis.get(redis_key(mailbox)).to_i
        
        unseen_uids = get_unseen_uids(mailbox, last_seen_uid)
        
        @logger.debug { "unseen_uids: #{unseen_uids}" }
        
        unseen_uids.each do |uid|
          @redis.set(redis_key(mailbox), uid)
          
          @notifiers.each { |n| n.notify(SIDEKIQ_JOB_CLASS, [mailbox, uid]) }
        end
        
        @logger.info { "#{mailbox} has #{unseen_uids.count} new emails" }
      end
      
      private
      
      def connect_service
        @imap = Net::IMAP.new(@imap_config[:host], {
          :port => @imap_config[:port],
          :ssl  => @imap_config[:ssl],
        })
        
        @imap.login(@imap_config[:username], @imap_config[:password])
      end
      
      def redis_key(mailbox)
        [
          REDIS_KEY_PREFIX,
          @imap_config[:host],
          @imap_config[:port],
          @imap_config[:username],
          mailbox,
        ].join(':')
      end
      
      def get_unseen_uids(mailbox, last_seen_uid = nil)
        @imap.select(mailbox)
        
        uids = @imap.uid_search("#{last_seen_uid + 1}:*")
        
        # filter as IMAP search gets fun with edge cases
        uids.find_all { |uid| uid > last_seen_uid }
      end
      
    end
  end
end
