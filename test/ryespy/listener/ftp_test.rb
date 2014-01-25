require_relative '../../helper'

require_relative '../../../lib/ryespy/listener/ftp'


describe Ryespy::Listener::FTP do
  
  before do
    @files = [
      'Bottlenose',
      'Haeviside',
      'Franciscana',
    ]
    
    @net_ftp = stub
    
    @net_ftp.stubs(:connect).with('ftp.example.com', 2121)
    @net_ftp.stubs(:passive=)
    @net_ftp.stubs(:login).with('d.adams', 'solongandthanksforallthefish')
    @net_ftp.stubs(:chdir).with('/dolphin')
    @net_ftp.stubs(:nlst).returns(@files)
    @net_ftp.stubs(:mtime).returns(-562032000)
    @net_ftp.stubs(:size).returns(42)
    @net_ftp.stubs(:close)
    
    Net::FTP.stubs(:new).returns(@net_ftp)
  end
  
  describe "#check" do
    before do
      Ryespy::Test::Redis::setup
      
      @notifier = mock()
      
      @ftp = Ryespy::Listener::FTP.new(
        :host      => 'ftp.example.com',
        :port      => 2121,
        :passive   => true,
        :username  => 'd.adams',
        :password  => 'solongandthanksforallthefish',
        :notifiers => [@notifier],
      )
      
      @redis = @ftp.instance_variable_get(:@redis)
    end
    
    after do
      @ftp.close
      
      Ryespy::Test::Redis::flush_namespace(@redis)
    end
    
    it "notifies when new files" do
      @files.each do |file|
        @notifier.expects(:notify).with('RyespyFTPJob', ['/dolphin', file]).once
      end
      
      @ftp.check('/dolphin')
    end
    
    it "doesn't notify when no new files" do
      @notifier.expects(:notify).times(3)
      
      @ftp.check('/dolphin')
      
      @notifier.expects(:notify).never
      
      @ftp.check('/dolphin')
    end
    
    it "notifies when changed mtime" do
      @notifier.expects(:notify).times(3)
      
      @ftp.check('/dolphin')
      
      @net_ftp.stubs(:mtime).with('Bottlenose').returns(-562031999)
      
      @notifier.expects(:notify).with('RyespyFTPJob', ['/dolphin', 'Bottlenose']).once
      
      @ftp.check('/dolphin')
    end
    
    it "notifies when changed size" do
      @notifier.expects(:notify).times(3)
      
      @ftp.check('/dolphin')
      
      @net_ftp.stubs(:size).with('Franciscana').returns(41)
      
      @notifier.expects(:notify).with('RyespyFTPJob', ['/dolphin', 'Franciscana']).once
      
      @ftp.check('/dolphin')
    end
  end
  
end
