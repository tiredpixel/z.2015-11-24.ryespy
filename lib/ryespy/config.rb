module Ryespy
  class Config
    
    attr_accessor :log_level
    attr_accessor :listener
    attr_accessor :polling_interval
    attr_accessor :redis_url
    attr_accessor :redis_ns_ryespy
    
    attr_accessor :imap_host
    attr_accessor :imap_port
    attr_accessor :imap_ssl
    attr_accessor :imap_username
    attr_accessor :imap_password
    attr_accessor :imap_mailboxes
    
    def initialize
      @log_level        = 'INFO'
      @polling_interval = 60
      @redis_ns_ryespy  = 'ryespy:'
      
      @imap_port      = 993
      @imap_ssl       = true
      @imap_mailboxes = ['INBOX']
    end
    
    def to_s
      params = [
        :log_level,
        :listener,
        :polling_interval,
        :redis_url,
        :redis_ns_ryespy,
      ]
      
      params.concat case @listener
      when :imap
        [
          :imap_host,
          :imap_port,
          :imap_ssl,
          :imap_username,
          :imap_password,
        ]
      else
        []
      end
      
      params.collect! { |s| [s, instance_variable_get("@#{s}")] }
      
      Hash[params].to_s
    end
    
  end
end
