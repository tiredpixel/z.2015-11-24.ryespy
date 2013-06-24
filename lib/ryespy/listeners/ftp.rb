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
      
    end
  end
end
