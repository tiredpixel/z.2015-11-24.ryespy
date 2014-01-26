require 'fog'

require_relative 'fogable'


module Ryespy
  module Listener
    class AmznS3 < Base
      
      include Listener::Fogable
      
      REDIS_KEY_PREFIX  = 'amzn_s3'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyAmznS3Job'.freeze
      
      def initialize(opts = {})
        @config = {
          :access_key => opts[:access_key],
          :secret_key => opts[:secret_key],
          :directory  => opts[:bucket],
        }
        
        super(opts)
      end
      
      private
      
      def connect_service
        @fog_storage = Fog::Storage.new({
          :provider              => 'AWS',
          :aws_access_key_id     => @config[:access_key],
          :aws_secret_access_key => @config[:secret_key],
        })
      end
      
    end
  end
end
