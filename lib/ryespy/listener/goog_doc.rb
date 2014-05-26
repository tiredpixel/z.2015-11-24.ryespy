require "google_drive"


module Ryespy
  module Listener
    class GoogDoc < Base

      REDIS_KEY_PREFIX  = 'goog_doc'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyGoogDocJob'.freeze

      def initialize(opts = {})
        @config = {
          :username => opts[:username],
          :password => opts[:password],
        }

        super(opts)
      end

      def check(prefix)
        @logger.debug { "prefix: #{prefix}" }

        @logger.debug { "redis_key: #{redis_key(prefix)}" }

        seen_files = @redis.hgetall(redis_key(prefix))

        unseen_files = get_unseen_files(prefix, seen_files)

        @logger.debug { "unseen_files: #{unseen_files}" }

        unseen_files.each do |filename, checksum|
          @redis.hset(redis_key(prefix), filename, checksum)

          @notifiers.each { |n| n.notify(SIDEKIQ_JOB_CLASS, [prefix, filename]) }
        end

        @logger.info { "#{prefix} has #{unseen_files.count} new files" }
      end

      private

      def connect_service
        @google_doc = GoogleDrive.login(@config[:username], @config[:password])
      end

      def redis_key(prefix)
        [
          REDIS_KEY_PREFIX,
          @config[:username],
          prefix,
        ].join(':')
      end

      def get_unseen_files(prefix, seen_files)
        files = {}
        
        @google_doc.files.each do |file|
          next unless file.title =~ /^#{prefix}/
          if seen_files[file.key] != file.key 
            files[file.key] = file.key
          end
        end

        files
      end

    end
  end
end
