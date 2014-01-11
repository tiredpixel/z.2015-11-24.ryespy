require 'redis'
require 'redis-namespace'
require 'json'
require 'securerandom'


module Ryespy
  module Notifier
    class Sidekiq
      
      SIDEKIQ_QUEUE = 'ryespy'.freeze
      
      def initialize(opts = {})
        @redis_config = {
          :url       => opts[:url],
          :namespace => opts[:namespace],
        }
        
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
        @redis.sadd("queues", SIDEKIQ_QUEUE)
        
        @redis.rpush("queue:#{SIDEKIQ_QUEUE}", {
          # resque
          :class => job_class,
          :args  => args,
          # sidekiq (extra)
          :queue => SIDEKIQ_QUEUE,
          :retry => true,
          :jid   => SecureRandom.hex(12),
        }.to_json)
      end
      
      private
      
      def connect_redis
        @redis = Redis::Namespace.new(@redis_config[:namespace],
          :redis => Redis.connect(:url => @redis_config[:url])
        )
      end
      
    end
  end
end
