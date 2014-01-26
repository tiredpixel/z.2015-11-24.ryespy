require 'logger'
require 'redis'
require 'fog'

require_relative 'fogable'


module Ryespy
  module Listener
    class RaxCF
      
      include Listener::Fogable
      
      REDIS_KEY_PREFIX  = 'rax_cf'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyRaxCFJob'.freeze
      
      def initialize(opts = {})
        @cf_config = {
          :auth_url  => Fog::Rackspace.const_get(
            "#{opts[:endpoint].upcase}_AUTH_ENDPOINT"
          ),
          :region    => opts[:region].to_sym,
          :username  => opts[:username],
          :api_key   => opts[:api_key],
          :directory => opts[:container],
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
          :provider           => 'Rackspace',
          :rackspace_auth_url => @cf_config[:auth_url],
          :rackspace_region   => @cf_config[:region],
          :rackspace_username => @cf_config[:username],
          :rackspace_api_key  => @cf_config[:api_key],
        })
      end
      
      def redis_key
        # CF container (directory) is unique across an account (region?).
        [
          REDIS_KEY_PREFIX,
          @cf_config[:username],
          @cf_config[:directory],
          @cf_config[:region],
        ].join(':')
      end
      
    end
  end
end
