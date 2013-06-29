require 'minitest/autorun'

require_relative '../../lib/ryespy'
require_relative '../../lib/ryespy/config'


describe Ryespy::Config do
  
  describe "default" do
    before do
      @config = Ryespy::Config.new
    end
    
    it "sets log_level to INFO" do
      @config.log_level.must_equal 'INFO'
    end
    
    it "sets polling_interval to 60" do
      @config.polling_interval.must_equal 60
    end
    
    it "sets redis_ns_ryespy to ryespy:" do
      @config.redis_ns_ryespy.must_equal 'ryespy:'
    end
    
    it "sets redis_ns_notifiers to resque:" do
      @config.redis_ns_notifiers.must_equal 'resque:'
    end
    
    it "sets notifiers hash structure" do
      @config.notifiers.must_equal({ :sidekiq => [] })
    end
    
    it "sets imap_port to 993" do
      @config.imap_port.must_equal 993
    end
    
    it "sets imap_ssl to true" do
      @config.imap_ssl.must_equal true
    end
    
    it "sets imap_mailboxes to INBOX" do
      @config.imap_mailboxes.must_equal ['INBOX']
    end
    
    it "sets ftp_passive to false" do
      @config.ftp_passive.must_equal false
    end
    
    it "sets ftp_dirs to /" do
      @config.ftp_dirs.must_equal ['/']
    end
  end
  
  describe "configure block main" do
    before do
      Ryespy.configure do |c|
        c.log_level           = 'ERROR'
        c.listener            = 'imap'
        c.polling_interval    = 13
        c.redis_url           = 'redis://127.0.0.1:6379/1'
        c.redis_ns_ryespy     = 'WithMyLittleEye!'
        c.redis_ns_notifiers  = 'LaLaLiLi-'
        c.notifiers           = [{ :sidekiq => 'redis://127.0.0.1:6379/2' }]
      end
      
      @config = Ryespy.config
    end
    
    it "configures log_level" do
      @config.log_level.must_equal 'ERROR'
    end
    
    it "configures listener" do
      @config.listener.must_equal 'imap'
    end
    
    it "configures polling_interval" do
      @config.polling_interval.must_equal 13
    end
    
    it "configures redis_url" do
      @config.redis_url.must_equal 'redis://127.0.0.1:6379/1'
    end
    
    it "configures redis_ns_ryespy" do
      @config.redis_ns_ryespy.must_equal 'WithMyLittleEye!'
    end
    
    it "configures redis_ns_notifiers" do
      @config.redis_ns_notifiers.must_equal 'LaLaLiLi-'
    end
    
    it "configures notifiers" do
      @config.notifiers.must_equal [{ :sidekiq => 'redis://127.0.0.1:6379/2' }]
    end
  end
  
  describe "configure block listener IMAP" do
    before do
      Ryespy.configure do |c|
        c.imap_host      = 'imap.example.com'
        c.imap_port      = 143
        c.imap_ssl       = false
        c.imap_username  = 'lucy.westenra@example.com'
        c.imap_password  = 'white'
        c.imap_mailboxes = 'BoxA,Sent Messages'
        
        @config = Ryespy.config
      end
    end
    
    it "configures imap_host" do
      @config.imap_host.must_equal 'imap.example.com'
    end
    
    it "configures imap_port" do
      @config.imap_port.must_equal 143
    end
    
    it "configures imap_ssl" do
      @config.imap_ssl.must_equal false
    end
    
    it "configures imap_username" do
      @config.imap_username.must_equal 'lucy.westenra@example.com'
    end
    
    it "configures imap_password" do
      @config.imap_password.must_equal 'white'
    end
    
    it "configures imap_mailboxes" do
      @config.imap_mailboxes.must_equal 'BoxA,Sent Messages'
    end
  end
  
  describe "configure block listener FTP" do
    before do
      Ryespy.configure do |c|
        c.ftp_host     = 'ftp.example.org'
        c.ftp_passive  = true
        c.ftp_username = 'madam.mina@example.com'
        c.ftp_password = 'black'
        c.ftp_dirs     = ['BoxA', 'Sent Messages']
        
        @config = Ryespy.config
      end
    end
    
    it "configures ftp_host" do
      @config.ftp_host.must_equal 'ftp.example.org'
    end
    
    it "configures ftp_passive" do
      @config.ftp_passive.must_equal true
    end
    
    it "configures ftp_username" do
      @config.ftp_username.must_equal 'madam.mina@example.com'
    end
    
    it "configures ftp_password" do
      @config.ftp_password.must_equal 'black'
    end
    
    it "configures ftp_dirs" do
      @config.ftp_dirs.must_equal ['BoxA', 'Sent Messages']
    end
  end
  
  describe "#to_s" do
    before do
      @config = Ryespy::Config.new
    end
    
    describe "when listener NULL" do
      before do
        @config.listener = nil
      end
      
      it "stringifies hash of config" do
        @config.to_s.must_equal '{:log_level=>"INFO", :listener=>nil, :polling_interval=>60, :redis_url=>nil, :redis_ns_ryespy=>"ryespy:", :redis_ns_notifiers=>"resque:", :notifiers=>{:sidekiq=>[]}}'
      end
    end
    
    describe "when listener IMAP" do
      before do
        @config.listener = 'imap'
      end
      
      it "stringifies hash of config" do
        @config.to_s.must_equal '{:log_level=>"INFO", :listener=>"imap", :polling_interval=>60, :redis_url=>nil, :redis_ns_ryespy=>"ryespy:", :redis_ns_notifiers=>"resque:", :notifiers=>{:sidekiq=>[]}, :imap_host=>nil, :imap_port=>993, :imap_ssl=>true, :imap_username=>nil, :imap_password=>nil}'
      end
    end
    
    describe "when listener FTP" do
      before do
        @config.listener = 'ftp'
      end
      
      it "stringifies hash of config" do
        @config.to_s.must_equal '{:log_level=>"INFO", :listener=>"ftp", :polling_interval=>60, :redis_url=>nil, :redis_ns_ryespy=>"ryespy:", :redis_ns_notifiers=>"resque:", :notifiers=>{:sidekiq=>[]}, :ftp_host=>nil, :ftp_passive=>false, :ftp_username=>nil, :ftp_dirs=>["/"]}'
      end
    end
  end
  
  describe "#redis_prefix_ryespy" do
    before do
      Ryespy.configure do |c|
        c.listener         = 'earear'
        c.redis_ns_ryespy  = 'LittleEye:'
      end
      
      @config = Ryespy.config
    end
    
    it "returns key prefix" do
      @config.redis_prefix_ryespy.must_equal "LittleEye:earear:"
    end
  end
  
end
