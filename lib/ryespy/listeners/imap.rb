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
      
      def check_all
        Ryespy.config.imap_mailboxes.each do |mailbox|
          Ryespy.logger.debug { "mailbox:#{mailbox}" }
          
          redis_key = "#{Ryespy.config.redis_prefix_ryespy}#{Ryespy.config.imap_host},#{Ryespy.config.imap_port}:#{Ryespy.config.imap_username}:#{mailbox}"
          
          Ryespy.logger.debug { "redis_key:#{redis_key}" }
          
          new_items = check({
            :mailbox       => mailbox,
            :last_seen_uid => Ryespy.redis.get(redis_key).to_i,
          })
          
          Ryespy.logger.debug { "new_items:#{new_items}" }
          
          new_items.each do |uid|
            Ryespy.redis.set(redis_key, uid)
            
            Ryespy.notifiers.each { |n| n.notify('RyespyIMAPJob', [mailbox, uid]) }
          end
          
          Ryespy.logger.info { "#{mailbox} has #{new_items.count} new emails" }
        end
      end
      
    end
  end
end
