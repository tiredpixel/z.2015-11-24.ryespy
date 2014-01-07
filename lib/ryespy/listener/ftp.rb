require 'logger'
require 'redis'
require 'net/ftp'


module Ryespy
  module Listener
    class FTP
      
      def initialize(opts = {})
        @config    = opts[:config] || Config.new
        @notifiers = opts[:notifiers] || []
        @logger    = opts[:logger] || Logger.new(nil)
        
        @redis = Redis.current
        
        begin
          @ftp = Net::FTP.new(@config.ftp_host)
          
          @ftp.passive = @config.ftp_passive
          
          @ftp.login(@config.ftp_username, @config.ftp_password)
        rescue Errno::ECONNREFUSED, Net::FTPError => e
          @logger.error { e.to_s }
          
          return
        end
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @ftp.close
      end
      
      def check(params)
        begin
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
        rescue Net::FTPError => e
          @logger.error { e.to_s }
          
          return
        end
      end
      
      def check_all
        @config.ftp_dirs.each do |dir|
          @logger.debug { "dir:#{dir}" }
          
          redis_key = "#{@config.redis_prefix_ryespy}#{@config.ftp_host}:#{@config.ftp_username}:#{dir}"
          
          @logger.debug { "redis_key:#{redis_key}" }
          
          new_items = check({
            :dir        => dir,
            :seen_files => @redis.hgetall(redis_key),
          })
          
          @logger.debug { "new_items:#{new_items}" }
          
          new_items.each do |filename, checksum|
            @redis.hset(redis_key, filename, checksum)
            
            @notifiers.each { |n| n.notify('RyespyFTPJob', [dir, filename]) }
          end
          
          @logger.info { "#{dir} has #{new_items.count} new files" }
        end
      end
      
    end
  end
end
