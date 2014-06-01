require "google_drive"


module Ryespy
  module Listener
    class GoogDrv < Base

      REDIS_KEY_PREFIX  = 'goog_drv'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyGoogDrvJob'.freeze

      def initialize(opts = {})
        @config = {
          :username => opts[:username],
          :password => opts[:password],
        }

        super(opts)
      end

      def check(filter)
        @logger.debug { "filter: #{filter}" }

        @logger.debug { "redis_key: #{redis_key}" }

        seen_files = @redis.hgetall(redis_key)

        unseen_files = get_unseen_files(filter, seen_files)

        @logger.debug { "unseen_files: #{unseen_files}" }

        unseen_files.each do |key, val|
          @redis.hset(redis_key, key, val)

          @notifiers.each { |n| n.notify(SIDEKIQ_JOB_CLASS, [key]) }
        end

        @logger.info { "#{filter} has #{unseen_files.count} new files" }
      end

      private

      def connect_service
        @google_drive = GoogleDrive.login(@config[:username], @config[:password])
      end

      def redis_key
        [
          REDIS_KEY_PREFIX,
          @config[:username]
        ].join(':')
      end

      def get_unseen_files(filter, seen_files)
        files = {}
        @google_drive.files.each do |file|

          next unless file.title =~ /#{filter}/ && file.resource_id && file.resource_type != 'folder'
          if seen_files[file.resource_id] != file.resource_id
            files[file.resource_id] = file.resource_id
          end
        end

        files
      end

    end
  end
end
