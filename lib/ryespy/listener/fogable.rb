module Ryespy
  module Listener
    module Fogable
      
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
          
          # prefix is not included as it is part of key, and list operations
          # return files (virtually) recursively. Constructing Redis key in this
          # way means a file matching multiple prefixes will only notify once.
          @notifiers.each do |notifier|
            notifier.notify(self.class::SIDEKIQ_JOB_CLASS, [filename])
          end
        end
        
        @logger.info { "#{prefix}* has #{unseen_files.count} new files" }
      end
      
      private
      
      def redis_key
        [
          self.class::REDIS_KEY_PREFIX,
          @config[:directory],
        ].join(':')
      end
      
      def get_unseen_files(prefix, seen_files)
        files = {}
        
        @fog_storage.directories.get(@config[:directory],
          :prefix => prefix
        ).files.each do |file|
          if file.content_type == 'application/directory' || file.content_length == 0
            next # virtual dirs or 0-length file
          end
          
          if seen_files[file.key] != file.etag # etag is server-side checksum
            files[file.key] = file.etag
          end
        end
        
        files
      end
      
    end
  end
end
