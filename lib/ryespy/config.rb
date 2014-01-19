module Ryespy
  class Config
    
    attr_accessor :log_level
    attr_accessor :listener
    attr_accessor :polling_interval
    attr_accessor :redis_url
    attr_accessor :redis_ns_ryespy
    attr_accessor :redis_ns_notifiers
    attr_accessor :notifiers
    
    attr_accessor :imap_host
    attr_accessor :imap_port
    attr_accessor :imap_ssl
    attr_accessor :imap_username
    attr_accessor :imap_password
    attr_accessor :imap_mailboxes
    
    attr_accessor :ftp_host
    attr_accessor :ftp_passive
    attr_accessor :ftp_username
    attr_accessor :ftp_password
    attr_accessor :ftp_dirs
    
    def initialize
      @log_level          = 'INFO'.freeze
      @polling_interval   = 60
      @redis_ns_ryespy    = 'ryespy'.freeze
      @redis_ns_notifiers = 'resque'.freeze
      @notifiers          = {
        :sidekiq => [],
      }
      
      @imap_port      = 993
      @imap_ssl       = true
      @imap_mailboxes = ['INBOX'.freeze]
      
      @ftp_passive    = false
      @ftp_dirs       = ['/'.freeze]
    end
    
    def to_s
      params = [
        :log_level,
        :listener,
        :polling_interval,
        :redis_url,
        :redis_ns_ryespy,
        :redis_ns_notifiers,
        :notifiers,
      ]
      
      params.concat case @listener.to_sym
      when :imap
        [
          :imap_host,
          :imap_port,
          :imap_ssl,
          :imap_username,
          :imap_password,
        ]
      when :ftp
        [
          :ftp_host,
          :ftp_passive,
          :ftp_username,
          :ftp_dirs,
        ]
      else
        []
      end
      
      params.collect! { |s| [s, instance_variable_get("@#{s}")] }
      
      Hash[params].to_s
    end
    
  end
end
