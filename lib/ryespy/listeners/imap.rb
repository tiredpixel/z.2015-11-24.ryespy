require 'net/imap'


module Ryespy
  module Listener
    class IMAP
      
      def initialize
        begin
          @imap = Net::IMAP.new(Ryespy.config.imap_host, {
            :port => Ryespy.config.imap_port,
            :ssl  => Ryespy.config.imap_ssl,
          })
          
          @imap.login(Ryespy.config.imap_username, Ryespy.config.imap_password)
        rescue Errno::ECONNREFUSED, Net::IMAP::Error => e
          Ryespy.logger.error { e.to_s }
          
          return
        end
        
        if block_given?
          yield self
          
          close
        end
      end
      
      def close
        @imap.logout
        
        @imap.disconnect
      end
      
      def check(params)
        begin
          @imap.select(params[:mailbox])
          
          uids = @imap.uid_search("#{params[:last_seen_uid] + 1}:*")
          
          uids.find_all { |uid| uid > params[:last_seen_uid] } # IMAP search gets fun with edge cases
        rescue Net::IMAP::Error => e
          Ryespy.logger.error { e.to_s }
          
          return
        end
      end
      
    end
  end
end
