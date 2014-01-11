require 'logger'
require 'redis'
require 'net/ftp'


module Ryespy
  module Listener
    class FTP
      
      def initialize(opts = {})
        @ftp_config = {
          :host     => opts[:host],
          :passive  => opts[:passive],
          :username => opts[:username],
          :password => opts[:password],
        }
        
        @ftp_dirs = opts[:dirs]
        
        @notifiers = opts[:notifiers] || []
        @logger    = opts[:logger] || Logger.new(nil)
        
        @redis = Redis.current
        
        connect_ftp
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @ftp.close
      end
      
      def check(params)
        @ftp.chdir(params[:dir])
        
        objects = {}
        
        @ftp.nlst.each do |fd|
          mtime = @ftp.mtime(fd).to_i
          size = @ftp.size(fd) rescue nil # ignore non-file error
          
          if size # exclude directories
            checksum = "#{mtime},#{size}"
            
            if params[:seen_files][fd] != checksum
              objects[fd] = checksum
            end
          end
        end
        
        objects
      end
      
      def check_all
        @ftp_dirs.each do |dir|
          @logger.debug { "dir:#{dir}" }
          
          redis_key = "#{@ftp_config[:host]}:#{@ftp_config[:username]}:#{dir}"
          
          @logger.debug { "redis_key:#{redis_key}" }
          
          begin
            new_items = check({
              :dir        => dir,
              :seen_files => @redis.hgetall(redis_key),
            })
          rescue Net::FTPError => e
            @logger.error { e.to_s }
          end
          
          @logger.debug { "new_items:#{new_items}" }
          
          new_items.each do |filename, checksum|
            @redis.hset(redis_key, filename, checksum)
            
            @notifiers.each { |n| n.notify('RyespyFTPJob', [dir, filename]) }
          end
          
          @logger.info { "#{dir} has #{new_items.count} new files" }
        end
      end
      
      private
      
      def connect_ftp
        @ftp = Net::FTP.new(@ftp_config[:host])
        
        @ftp.passive = @ftp_config[:passive]
        
        @ftp.login(@ftp_config[:username], @ftp_config[:password])
      end
      
    end
  end
end
