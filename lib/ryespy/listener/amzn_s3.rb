require 'logger'
require 'redis'
require 'fog'

require_relative 'fogable'


module Ryespy
  module Listener
    class AmznS3
      
      include Listener::Fogable
      
      REDIS_KEY_PREFIX  = 'amzn_s3'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyAmznS3Job'.freeze
      
      def initialize(opts = {})
        @cf_config = {
          :access_key => opts[:access_key],
          :secret_key => opts[:secret_key],
          :directory  => opts[:bucket],
        }
        
        @notifiers = opts[:notifiers] || []
        @logger    = opts[:logger] || Logger.new(nil)
        
        @redis = Redis.current
        
        connect_fog_storage
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
      end
      
      private
      
      def connect_fog_storage
        @fog_storage = Fog::Storage.new({
          :provider              => 'AWS',
          :aws_access_key_id     => @cf_config[:access_key],
          :aws_secret_access_key => @cf_config[:secret_key],
        })
      end
      
      def redis_key
        # S3 bucket (directory) is unique across all accounts and regions.
        [
          REDIS_KEY_PREFIX,
          @cf_config[:directory],
        ].join(':')
      end
      
    end
  end
end
