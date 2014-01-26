require 'logger'
require 'redis'
require 'fog'

require_relative 'fogable'


module Ryespy
  module Listener
    class GoogCS
      
      include Listener::Fogable
      
      REDIS_KEY_PREFIX  = 'goog_cs'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyGoogCSJob'.freeze
      
      def initialize(opts = {})
        @config = {
          :access_key => opts[:access_key],
          :secret_key => opts[:secret_key],
          :directory  => opts[:bucket],
        }
        
        @notifiers = opts[:notifiers] || []
        @logger    = opts[:logger] || Logger.new(nil)
        
        @redis = Redis.current
        
        connect_service
        
        if block_given?
          yield self
          
          close
        end
      end
      
      private
      
      def connect_service
        @fog_storage = Fog::Storage.new({
          :provider                         => 'Google',
          :google_storage_access_key_id     => @config[:access_key],
          :google_storage_secret_access_key => @config[:secret_key],
        })
      end
      
    end
  end
end
