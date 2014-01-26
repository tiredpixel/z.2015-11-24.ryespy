require_relative '../../helper'

require_relative '../../../lib/ryespy/listener/rax_cf'


describe Ryespy::Listener::RaxCF do
  
  before do
    etag = 'dvYAPmJPy8nyqtR8hqqPYIagWEDuZ9FN'
    
    @files = [
      stub(:content_length => 0, :content_type => 'application/directory', :key => 'abraham/',             :etag => etag),
      stub(:content_length => 1, :content_type => 'text/plain',            :key => 'abraham/a.txt',        :etag => etag),
      stub(:content_length => 1, :content_type => 'text/plain',            :key => 'abraham/b.txt',        :etag => etag),
      stub(:content_length => 0, :content_type => 'application/directory', :key => 'a/',                   :etag => etag),
      stub(:content_length => 1, :content_type => 'text/plain',            :key => 'a/abraham_README.txt', :etag => etag),
      stub(:content_length => 0, :content_type => 'application/directory', :key => 'van/',                 :etag => etag),
      stub(:content_length => 1, :content_type => 'text/plain',            :key => 'van/van.txt',          :etag => etag),
    ]
    
    @files_no_dirs = @files.select { |f| f.content_type != 'application/directory' }
    
    @fog_storage = stub
    
    @fog_storage_directories = stub
    
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => 'abraham/'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^abraham\// }))
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => 'a'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^a/ }))
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => 'van/'
    }).returns(stub(:files => @files.select { |f| f.key =~ /^van\// }))
    @fog_storage_directories.stubs(:get).with('tmtiscnoa', {
      :prefix => ''
    }).returns(stub(:files => @files))
    
    @fog_storage.stubs(:directories).returns(@fog_storage_directories)
    
    Fog::Storage.stubs(:new).with({
      :provider           => 'Rackspace',
      :rackspace_auth_url => 'https://lon.identity.api.rackspacecloud.com/v2.0',
      :rackspace_region   => :lon,
      :rackspace_username => 'van.helsing',
      :rackspace_api_key  => 'M.D., D.Ph., D.Litt., etc.',
    }).returns(@fog_storage)
  end
  
  describe "#check" do
    before do
      Ryespy::Test::Redis::setup
      
      @notifier = mock()
      
      @rax_cf = Ryespy::Listener::RaxCF.new(
        :endpoint  => 'uk',
        :region    => 'lon',
        :username  => 'van.helsing',
        :api_key   => 'M.D., D.Ph., D.Litt., etc.',
        :container => 'tmtiscnoa',
        :notifiers => [@notifier],
      )
      
      @redis = @rax_cf.instance_variable_get(:@redis)
    end
    
    after do
      @rax_cf.close
      
      Ryespy::Test::Redis::flush_namespace(@redis)
    end
    
    it "notifies when new files prefix *" do
      @files_no_dirs.each do |file|
        @notifier.expects(:notify).with('RyespyRaxCFJob', [file.key]).once
      end
      
      @rax_cf.check('')
    end
    
    it "notifies when new files prefix van/" do
      @files_no_dirs.select { |f| f.key =~ /^van\// }.each do |file|
        @notifier.expects(:notify).with('RyespyRaxCFJob', [file.key]).once
      end
      
      @rax_cf.check('van/')
    end
    
    it "notifies when new files prefix a" do
      @files_no_dirs.select { |f| f.key =~ /^a/ }.each do |file|
        @notifier.expects(:notify).with('RyespyRaxCFJob', [file.key]).once
      end
      
      @rax_cf.check('a')
    end
    
    it "doesn't notify when no new files" do
      @notifier.expects(:notify).times(2)
      
      @rax_cf.check('abraham/')
      
      @notifier.expects(:notify).never
      
      @rax_cf.check('abraham/')
    end
    
    it "doesn't notify when no new files prefix subset" do
      @notifier.expects(:notify).times(3)
      
      @rax_cf.check('a')
      
      @notifier.expects(:notify).never
      
      @rax_cf.check('abraham/')
    end
    
    it "notifies when new files prefix distinct" do
      @notifier.expects(:notify).times(3)
      
      @rax_cf.check('a')
      
      @notifier.expects(:notify).times(1)
      
      @rax_cf.check('van/')
    end
    
    it "notifies when changed etag" do
      @notifier.expects(:notify).times(2)
      
      @rax_cf.check('abraham/')
      
      @files[1].stubs(:etag).returns(-2303600400)
      
      @notifier.expects(:notify).with('RyespyRaxCFJob', ['abraham/a.txt']).once
      
      @rax_cf.check('abraham/')
    end
  end
  
end
