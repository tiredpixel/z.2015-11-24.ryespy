require 'net/ftp'


module Ryespy
  module Listener
    class FTP
      
      def initialize
        begin
          @ftp = Net::FTP.new(Ryespy.config.ftp_host)
          
          @ftp.passive = Ryespy.config.ftp_passive
          
          @ftp.login(Ryespy.config.ftp_username, Ryespy.config.ftp_password)
        rescue Errno::ECONNREFUSED, Net::FTPError => e
          Ryespy.logger.error { e.to_s }
          
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
          Ryespy.logger.error { e.to_s }
          
          return
        end
      end
      
      def check_all
        Ryespy.config.ftp_dirs.each do |dir|
          Ryespy.logger.debug { "dir:#{dir}" }
          
          redis_key = "#{Ryespy.config.redis_prefix_ryespy}#{Ryespy.config.ftp_host}:#{Ryespy.config.ftp_username}:#{dir}"
          
          Ryespy.logger.debug { "redis_key:#{redis_key}" }
          
          new_items = check({
            :dir        => dir,
            :seen_files => Ryespy.redis.hgetall(redis_key),
          })
          
          Ryespy.logger.debug { "new_items:#{new_items}" }
          
          new_items.each do |filename, checksum|
            Ryespy.redis.hset(redis_key, filename, checksum)
            
            Ryespy.notifiers.each { |n| n.notify('RyespyFTPJob', [dir, filename]) }
          end
          
          Ryespy.logger.info { "#{dir} has #{new_items.count} new files" }
        end
      end
      
    end
  end
end
