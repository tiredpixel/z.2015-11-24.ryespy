require_relative '../../helper'

require_relative '../../../lib/ryespy/listener/goog_drv'


describe Ryespy::Listener::GoogDrv do
  
  before do
    updated = '1897-05-26 00:00:00 UTC'
    
    dfe = stub
    dfe.stubs(:css).with('updated').returns([stub(:text => updated)])
    dfe.stubs(:attribute).with('etag').returns('E13l2izwZbgWKfS5')
    
    dfe2 = stub
    dfe2.stubs(:css).with('updated').returns([stub(:text => updated)])
    dfe2.stubs(:attribute).with('etag').returns(nil)
    
    @files = [
      stub(
        :resource_id         => 'folder:FFTSKJtqo5v2TRrIADAmVOlsqe8h9TqM',
        :resource_type       => 'folder',
        :title               => 'Flies/',
        :document_feed_entry => dfe,
      ),
      stub(
        :resource_id         => 'presentation:SuOQSdIwu3E58fq7HsbtfjG2aeuTDtOJ',
        :resource_type       => 'presentation',
        :title               => 'Flies Presentation',
        :document_feed_entry => dfe,
      ),
      stub(
        :resource_id         => 'spreadsheet:GfVKovEtmvWtMgWDTv94kcYZLbje1O3q',
        :resource_type       => 'spreadsheet',
        :title               => 'Flies Spreadsheet',
        :document_feed_entry => dfe2,
      ),
      stub(
        :resource_id         => 'drawing:ceKiP0rwNufPU3qguhleVIxmtXqMjaWe',
        :resource_type       => 'drawing',
        :title               => 'FliesBuzz Drawing',
        :document_feed_entry => dfe,
      ),
      stub(
        :resource_id         => 'form:OCBeiWQf51qvmPdWVT8olFRqTM8pl5sC',
        :resource_type       => 'form',
        :title               => 'Spiders and Flies Form',
        :document_feed_entry => dfe,
      ),
      stub(
        :resource_id         => 'document:gvZHG5YA5rkcgIXGUnDXhMOI0qE7WKnm',
        :resource_type       => 'document',
        :title               => 'Spiders Document',
        :document_feed_entry => dfe,
      ),
      stub(
        :resource_id         => 'file:i7iqdRt3CxbJEWuo8kXIFBe9WeTnQRL3',
        :resource_type       => 'file',
        :title               => 'Spiders File',
        :document_feed_entry => dfe,
      ),
    ]
    
    @files_no_dirs = @files.select { |f| f.resource_type != 'folder' }
    
    @google_drive = stub(
      :files => @files
    )
    
    GoogleDrive.stubs(:login).with('r.m.renfield', 'master').returns(@google_drive)
  end
  
  describe "#check" do
    before do
      Ryespy::Test::Redis::setup
      
      @notifier = mock()
      
      @goog_drv = Ryespy::Listener::GoogDrv.new(
        :username  => 'r.m.renfield',
        :password  => 'master',
        :notifiers => [@notifier],
      )
      
      @redis = @goog_drv.instance_variable_get(:@redis)
    end
    
    after do
      @goog_drv.close
      
      Ryespy::Test::Redis::flush_namespace(@redis)
    end
    
    it "notifies when new files filter *" do
      @files_no_dirs.each do |file|
        @notifier.expects(:notify).with('RyespyGoogDrvJob', [file.resource_id]).once
      end
      
      @goog_drv.check('')
    end
    
    it "notifies when new files filter ^Flies\\b" do
      @files_no_dirs.select { |f| f.title =~ /^Flies\b/ }.each do |file|
        @notifier.expects(:notify).with('RyespyGoogDrvJob', [file.resource_id]).once
      end
      
      @goog_drv.check('^Flies\b')
    end
    
    it "notifies when new files filter Flies" do
      @files_no_dirs.select { |f| f.title =~ /Flies/ }.each do |file|
        @notifier.expects(:notify).with('RyespyGoogDrvJob', [file.resource_id]).once
      end
      
      @goog_drv.check('Flies')
    end
    
    it "doesn't notify when no new files" do
      @notifier.expects(:notify).times(3)
      
      @goog_drv.check('Spiders')
      @goog_drv.check('Spiders')
    end
    
    it "doesn't notify when no new files filter subset" do
      @notifier.expects(:notify).times(3)
      
      @goog_drv.check('Spiders')
      @goog_drv.check('Spiders\ and\ Flies')
    end
    
    it "notifies when new files filter distinct" do
      @notifier.expects(:notify).times(4)
      
      @goog_drv.check('Spiders\ and\ Flies')
      @goog_drv.check('Flies')
    end
    
    it "notifies when changed updated" do
      dfe = stub
      dfe.stubs(:css).with('updated').returns([stub(:text => '1899-03-23 01:00:00 UTC')])
      dfe.stubs(:attribute).with('etag').returns('E13l2izwZbgWKfS5')
      
      @notifier.expects(:notify).times(4)
      
      @goog_drv.check('Flies')
      
      @files[1].stubs(:document_feed_entry).returns(dfe)
      
      @notifier.expects(:notify).with('RyespyGoogDrvJob', ['presentation:SuOQSdIwu3E58fq7HsbtfjG2aeuTDtOJ']).once
      
      @goog_drv.check('Flies')
    end
    
    it "notifies when changed etag" do
      dfe = stub
      dfe.stubs(:css).with('updated').returns([stub(:text => '1897-05-26 00:00:00 UTC')])
      dfe.stubs(:attribute).with('etag').returns('qGE4UWIcITePyidC')
      
      @notifier.expects(:notify).times(4)
      
      @goog_drv.check('Flies')
      
      @files[3].stubs(:document_feed_entry).returns(dfe)
      
      @notifier.expects(:notify).with('RyespyGoogDrvJob', ['drawing:ceKiP0rwNufPU3qguhleVIxmtXqMjaWe']).once
      
      @goog_drv.check('Flies')
    end
  end
  
end
