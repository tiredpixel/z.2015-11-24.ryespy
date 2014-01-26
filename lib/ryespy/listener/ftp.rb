require 'net/ftp'


module Ryespy
  module Listener
    class FTP < Base
      
      REDIS_KEY_PREFIX  = 'ftp'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyFTPJob'.freeze
      
      def initialize(opts = {})
        @ftp_config = {
          :host     => opts[:host],
          :port     => opts[:port],
          :passive  => opts[:passive],
          :username => opts[:username],
          :password => opts[:password],
        }
        
        super(opts)
      end
      
      def close
        @ftp.close
      end
      
      def check(dir)
        @logger.debug { "dir: #{dir}" }
        
        @logger.debug { "redis_key: #{redis_key(dir)}" }
        
        seen_files = @redis.hgetall(redis_key(dir))
        
        unseen_files = get_unseen_files(dir, seen_files)
        
        @logger.debug { "unseen_files: #{unseen_files}" }
        
        unseen_files.each do |filename, checksum|
          @redis.hset(redis_key(dir), filename, checksum)
          
          @notifiers.each { |n| n.notify(SIDEKIQ_JOB_CLASS, [dir, filename]) }
        end
        
        @logger.info { "#{dir} has #{unseen_files.count} new files" }
      end
      
      private
      
      def connect_service
        @ftp = Net::FTP.new
        
        @ftp.connect(@ftp_config[:host], @ftp_config[:port])
        
        @ftp.passive = @ftp_config[:passive]
        
        @ftp.login(@ftp_config[:username], @ftp_config[:password])
      end
      
      def redis_key(dir)
        [
          REDIS_KEY_PREFIX,
          @ftp_config[:host],
          @ftp_config[:port],
          @ftp_config[:username],
          dir,
        ].join(':')
      end
      
      def get_unseen_files(dir, seen_files)
        @ftp.chdir(dir)
        
        files = {}
        
        @ftp.nlst.each do |file|
          mtime = @ftp.mtime(file).to_i
          size = @ftp.size(file) rescue nil # ignore non-file error
          
          if size # exclude directories
            checksum = "#{mtime},#{size}".freeze
            
            if seen_files[file] != checksum
              files[file] = checksum
            end
          end
        end
        
        files
      end
      
    end
  end
end
