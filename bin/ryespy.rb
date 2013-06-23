#!/usr/bin/env ruby

$stdout.sync = true

require 'optparse'

require File.expand_path(File.dirname(__FILE__) + '/../lib/ryespy')


# = Parse opts

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: ryespy [options]"
  
  opts.separator ""
  opts.separator "Polling:"
  
  opts.on("-e", "--[no-]eternal", "Run eternally") do |o|
    options[:eternal] = o
  end
  
  opts.on("--polling-interval [N]", "Poll every N seconds when --eternal") do |o|
    options[:polling_interval] = o.to_i
  end
  
  opts.separator ""
  opts.separator "Other:"
  
  opts.on("-v", "--[no-]verbose", "Be somewhat verbose") do |o|
    options[:verbose] = o
  end
  
  opts.on_tail("--help", "Show this message") do
    puts opts
    exit
  end
  
  opts.on_tail("--version", "Show version") do
    puts "Ryespy version:#{Ryespy::VERSION}"
    exit
  end
end.parse!


# = Configure

Ryespy.configure do |c|
  c.log_level = 'DEBUG' if options[:verbose]
  
  c.polling_interval = options[:polling_interval] if options[:polling_interval]
end

@logger = Ryespy.logger


# = Main loop

loop do
  # TODO: Poll listener.
  
  break unless options[:eternal]
  
  @logger.debug { "Snoring for #{Ryespy.config.polling_interval} s" }
  
  sleep Ryespy.config.polling_interval # Sleep awhile.
end
