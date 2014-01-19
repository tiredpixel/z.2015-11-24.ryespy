require_relative '../../helper'

require_relative '../../../lib/ryespy/listener/imap'


describe Ryespy::Listener::IMAP do
  
  before do
    @uids = [6, 7, 42]
    
    @net_imap = stub
    
    @net_imap.stubs(:login).with('d.adams', 'solongandthanksforallthefish')
    @net_imap.stubs(:select).with('Dolphin')
    @net_imap.stubs(:uid_search).with('1:*').returns(@uids)
    @net_imap.stubs(:uid_search).with('43:*').returns([])
    @net_imap.stubs(:disconnect)
    
    Net::IMAP.stubs(:new).with('imap.example.com', {
      :port => 42,
      :ssl  => true,
    }).returns(@net_imap)
  end
  
  describe "#check" do
    before do
      Ryespy::Test::Redis::setup
      
      @notifier = mock()
      
      @imap = Ryespy::Listener::IMAP.new(
        :host      => 'imap.example.com',
        :port      => 42,
        :ssl       => true,
        :username  => 'd.adams',
        :password  => 'solongandthanksforallthefish',
        :notifiers => [@notifier],
      )
      
      @redis = @imap.instance_variable_get(:@redis)
    end
    
    after do
      @imap.close
      
      Ryespy::Test::Redis::flush_namespace(@redis)
    end
    
    it "notifies when new files" do
      @uids.each do |uid|
        @notifier.expects(:notify).with('RyespyIMAPJob', ['Dolphin', uid]).once
      end
      
      @imap.check('Dolphin')
    end
    
    it "doesn't notify when no new files" do
      @notifier.expects(:notify).times(3)
      
      @imap.check('Dolphin')
      
      @notifier.expects(:notify).never
      
      @imap.check('Dolphin')
    end
  end
  
end
