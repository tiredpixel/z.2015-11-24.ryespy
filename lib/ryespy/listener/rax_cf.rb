require 'logger'
require 'redis'
require 'fog'


module Ryespy
  module Listener
    class RaxCF
      
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
          :container => opts[:container],
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
      
      def check(prefix)
        @logger.debug { "prefix: #{prefix}" }
        
        @logger.debug { "redis_key: #{redis_key}" }
        
        seen_files = @redis.hgetall(redis_key)
        
        unseen_files = get_unseen_files(prefix, seen_files)
        
        @logger.debug { "unseen_files: #{unseen_files}" }
        
        unseen_files.each do |filename, checksum|
          @redis.hset(redis_key, filename, checksum)
          
          # SEE: #redis_key for why prefix is not passed to notifiers
          @notifiers.each { |n| n.notify(SIDEKIQ_JOB_CLASS, [filename]) }
        end
        
        @logger.info { "#{prefix}* has #{unseen_files.count} new files" }
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
        # CF prefix is not included as it is part of CF key, and list operations
        # return files (virtually) recursively. Constructing Redis key in this
        # way means a file matching multiple prefixes will only notify once.
        [
          REDIS_KEY_PREFIX,
          @cf_config[:username],
          @cf_config[:container],
          @cf_config[:region],
        ].join(':')
      end
      
      def get_unseen_files(prefix, seen_files)
        files = {}
        
        @fog_storage.directories.get(@cf_config[:container],
          :prefix => prefix
        ).files.each do |file|
          next if file.content_type == 'application/directory' # virtual dirs
          
          if seen_files[file.key] != file.etag # etag is server-side checksum
            files[file.key] = file.etag
          end
        end
        
        files
      end
      
    end
  end
end
