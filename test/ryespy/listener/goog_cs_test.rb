require_relative '../../helper'

require_relative '../../../lib/ryespy/listener/goog_cs'


describe Ryespy::Listener::GoogCS do
  
  before do
    etag = 'QpD453wgum7qpJKUZaeHgcnHtGabP6CS'
    
    @files = [
      stub(:content_length => 0, :content_type => '', :key => 'flies/',             :etag => etag),
      stub(:content_length => 1, :content_type => '', :key => 'flies/a.txt',        :etag => etag),
      stub(:content_length => 1, :content_type => '', :key => 'flies/b.txt',        :etag => etag),
      stub(:content_length => 0, :content_type => '', :key => 'f/',                 :etag => etag),
      stub(:content_length => 1, :content_type => '', :key => 'f/flies_README.txt', :etag => etag),
      stub(:content_length => 0, :content_type => '', :key => 'spiders/',           :etag => etag),
      stub(:content_length => 1, :content_type => '', :key => 'spiders/spider.txt', :etag => etag),
    ]
    
    @files_no_dirs = @files.select { |f| f.content_length != 0 }
    
    @fog_storage = stub
    
    @fog_storage_directories = stub
    
    @fog_storage_directories.stubs(:get).with('icw', {
      :prefix => 'flies/'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^flies\// }))
    @fog_storage_directories.stubs(:get).with('icw', {
      :prefix => 'f'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^f/ }))
    @fog_storage_directories.stubs(:get).with('icw', {
      :prefix => 'spiders/'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^spiders\// }))
    @fog_storage_directories.stubs(:get).with('icw', {
      :prefix => ''
    }).returns(stub(:files => @files))
    
    @fog_storage.stubs(:directories).returns(@fog_storage_directories)
    
    Fog::Storage.stubs(:new).with({
      :provider                         => 'Google',
      :google_storage_access_key_id     => 'r.m.renfield',
      :google_storage_secret_access_key => 'master',
    }).returns(@fog_storage)
  end
  
  describe "#check" do
    before do
      Ryespy::Test::Redis::setup
      
      @notifier = mock()
      
      @goog_cs = Ryespy::Listener::GoogCS.new(
        :access_key => 'r.m.renfield',
        :secret_key => 'master',
        :bucket     => 'icw',
        :notifiers  => [@notifier],
      )
      
      @redis = @goog_cs.instance_variable_get(:@redis)
    end
    
    after do
      @goog_cs.close
      
      Ryespy::Test::Redis::flush_namespace(@redis)
    end
    
    it "notifies when new files prefix *" do
      @files_no_dirs.each do |file|
        @notifier.expects(:notify).with('RyespyGoogCSJob', [file.key]).once
      end
      
      @goog_cs.check('')
    end
    
    it "notifies when new files prefix spiders/" do
      @files_no_dirs.select { |f| f.key =~ /^spiders\// }.each do |file|
        @notifier.expects(:notify).with('RyespyGoogCSJob', [file.key]).once
      end
      
      @goog_cs.check('spiders/')
    end
    
    it "notifies when new files prefix f" do
      @files_no_dirs.select { |f| f.key =~ /^f/ }.each do |file|
        @notifier.expects(:notify).with('RyespyGoogCSJob', [file.key]).once
      end
      
      @goog_cs.check('f')
    end
    
    it "doesn't notify when no new files" do
      @notifier.expects(:notify).times(2)
      
      @goog_cs.check('flies/')
      
      @notifier.expects(:notify).never
      
      @goog_cs.check('flies/')
    end
    
    it "doesn't notify when no new files prefix subset" do
      @notifier.expects(:notify).times(3)
      
      @goog_cs.check('f')
      
      @notifier.expects(:notify).never
      
      @goog_cs.check('flies/')
    end
    
    it "notifies when new files prefix distinct" do
      @notifier.expects(:notify).times(3)
      
      @goog_cs.check('f')
      
      @notifier.expects(:notify).times(1)
      
      @goog_cs.check('spiders/')
    end
    
    it "notifies when changed etag" do
      @notifier.expects(:notify).times(2)
      
      @goog_cs.check('flies/')
      
      @files[1].stubs(:etag).returns(-2303600400)
      
      @notifier.expects(:notify).with('RyespyGoogCSJob', ['flies/a.txt']).once
      
      @goog_cs.check('flies/')
    end
  end
  
end
