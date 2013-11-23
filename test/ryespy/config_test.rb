require 'minitest/autorun'

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
      @config = Ryespy::Config.new
      
      @config.listener        = 'earear'
      @config.redis_ns_ryespy = 'LittleEye:'
    end
    
    it "returns key prefix" do
      @config.redis_prefix_ryespy.must_equal "LittleEye:earear:"
    end
  end
  
end
