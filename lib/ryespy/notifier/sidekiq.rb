require 'redis'
require 'json'
require 'securerandom'


module Ryespy
  module Notifier
    class Sidekiq
      
      RESQUE_QUEUE = 'ryespy'
      
      def initialize(url = nil, opts = {})
        @config = opts[:config] || Config.new
        
        @redis = Redis.connect(:url => url)
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @redis.quit
      end
      
      def notify(job_class, args)
        @redis.sadd("#{@config.redis_ns_notifiers}queues", RESQUE_QUEUE)
        
        @redis.rpush("#{@config.redis_ns_notifiers}queue:#{RESQUE_QUEUE}", {
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
