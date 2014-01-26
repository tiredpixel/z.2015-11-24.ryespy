require 'logger'
require 'redis'
require 'redis-namespace'
require 'json'
require 'securerandom'


module Ryespy
  module Notifier
    class Sidekiq
      
      SIDEKIQ_QUEUE       = 'ryespy'.freeze
      SIDEKIQ_KEY_QUEUES  = 'queues'.freeze
      SIDEKIQ_KEY_QUEUE_X = "queue:#{SIDEKIQ_QUEUE}".freeze
      
      def initialize(opts = {})
        @redis_config = {
          :url       => opts[:url],
          :namespace => opts[:namespace],
        }
        
        @logger = opts[:logger] || Logger.new(nil)
        
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
        @redis.sadd(SIDEKIQ_KEY_QUEUES, SIDEKIQ_QUEUE)
        
        sidekiq_job_payload = sidekiq_job(job_class, args)
        
        @logger.debug { "Setting Redis Key #{SIDEKIQ_KEY_QUEUE_X} Payload #{sidekiq_job_payload.to_json}" }
        
        @redis.rpush(SIDEKIQ_KEY_QUEUE_X, sidekiq_job_payload.to_json)
      end
      
      private
      
      def connect_redis
        @redis = Redis::Namespace.new(@redis_config[:namespace],
          :redis => Redis.connect(:url => @redis_config[:url])
        )
      end
      
      def sidekiq_job(job_class, args)
        {
          # resque
          :class => job_class,
          :args  => args,
          # sidekiq (extra)
          :queue => SIDEKIQ_QUEUE,
          :retry => true,
          :jid   => SecureRandom.hex(12),
        }
      end
      
    end
  end
end
