require 'redis'
require 'json'
require 'securerandom'


module Ryespy
  module Notifier
    class Sidekiq
      
      RESQUE_QUEUE = 'ryespy'
      
      def initialize(opts = {})
        @redis_config = {
          :url => opts[:url],
        }
        
        @redis_ns_notifiers = opts[:redis_ns_notifiers]
        
        connect_redis
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @redis.quit
      end
      
      def notify(job_class, args)
        @redis.sadd("#{@redis_ns_notifiers}queues", RESQUE_QUEUE)
        
        @redis.rpush("#{@redis_ns_notifiers}queue:#{RESQUE_QUEUE}", {
          # resque
          :class => job_class,
          :args  => args,
          # sidekiq (extra)
          :queue => RESQUE_QUEUE,
          :retry => true,
          :jid   => SecureRandom.hex(12),
        }.to_json)
      end
      
      private
      
      def connect_redis
        @redis = Redis.connect(:url => @redis_config[:url])
      end
      
    end
  end
end
