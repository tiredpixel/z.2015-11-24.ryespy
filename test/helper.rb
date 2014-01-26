require 'minitest/autorun'
require 'mocha/setup'
require 'securerandom'
require 'json'
require 'redis'
require 'redis-namespace'


module Ryespy
  module Test
    
    def self.config
      @config ||= {
        :redis => {
          :url       => ENV['REDIS_URL'], # defaults
          :namespace => 'ryespy:test',
        },
      }
    end
    
    module Redis
      
      def self.setup
        ::Redis.current = ::Redis::Namespace.new(self.namespace,
          :redis => ::Redis.connect(:url => Ryespy::Test.config[:redis][:url])
        )
      end
      
      def self.namespace
        "#{Ryespy::Test.config[:redis][:namespace]}:#{SecureRandom.hex}"
      end
      
      def self.flush_namespace(redis)
        # Redis::Namespace means only namespaced keys removed
        redis.keys('*').each { |k| redis.del(k) }
      end
      
    end
    
  end
end
