require 'json'
require 'securerandom'

require_relative '../redis_conn'


module Ryespy
  module Notifier
    class Sidekiq
      
      RESQUE_QUEUE = 'ryespy'
      
      def initialize(url = nil)
        begin
          @redis_conn = Ryespy::RedisConn.new(url)
        rescue Errno::ECONNREFUSED, Net::FTPError => e
          Ryespy.logger.error { e.to_s }
          
          return
        end
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @redis_conn.close
      end
      
      def notify(job_class, args)
        @redis_conn.redis.sadd("#{Ryespy.config.redis_ns_notifiers}queues", RESQUE_QUEUE)
        
        @redis_conn.redis.rpush("#{Ryespy.config.redis_ns_notifiers}queue:#{RESQUE_QUEUE}", {
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
