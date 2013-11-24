require 'logger'
require 'json'
require 'securerandom'

require_relative '../redis_conn'


module Ryespy
  module Notifier
    class Sidekiq
      
      RESQUE_QUEUE = 'ryespy'
      
      def initialize(url = nil, opts = {})
        @config = opts[:config] || Config.new
        @logger = opts[:logger] || Logger.new(nil)
        
        @redis_conn = RedisConn.new(url,
          :logger => @logger
        )
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @redis_conn.close
      end
      
      def notify(job_class, args)
        @redis_conn.redis.sadd("#{@config.redis_ns_notifiers}queues", RESQUE_QUEUE)
        
        @redis_conn.redis.rpush("#{@config.redis_ns_notifiers}queue:#{RESQUE_QUEUE}", {
          # resque
          :class => job_class,
          :args  => args,
          # sidekiq (extra)
          :queue => RESQUE_QUEUE,
          :retry => true,
          :jid   => SecureRandom.hex(12),
        }.to_json)
      end
      
    end
  end
end
