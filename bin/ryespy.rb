#!/usr/bin/env ruby

$stdout.sync = true

require 'optparse'

require File.expand_path(File.dirname(__FILE__) + '/../lib/ryespy')


# = Parse opts

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: ryespy [options]"
  
  opts.separator ""
  opts.separator "Listener:"
  
  opts.on("-l", "--listener LISTENER", [:imap, :ftp], "Listener (imap|ftp)") do |o|
    options[:listener] = o
  end
  
  opts.separator ""
  opts.separator "Polling:"
  
  opts.on("-e", "--[no-]eternal", "Run eternally") do |o|
    options[:eternal] = o
  end
  
  opts.on("--polling-interval [N]", Integer, "Poll every N seconds when --eternal") do |o|
    options[:polling_interval] = o
  end
  
  opts.separator ""
  opts.separator "Redis:"
  
  opts.on("--redis-url [URL]", "Connect Redis to URL") do |o|
    options[:redis_url] = o
  end
  
  opts.on("--redis-ns-ryespy [NS]", "Namespace Redis 'ryespy:' as NS") do |o|
    options[:redis_ns_ryespy] = o
  end
  
  opts.separator ""
  opts.separator "Listener imap:"
  
  opts.on("-h", "--imap-host HOST", "Connect IMAP with HOST") do |o|
    options[:imap_host] = o
  end
  
  opts.on("--imap-port [PORT]", Integer, "Connect IMAP with PORT") do |o|
    options[:imap_port] = o
  end
  
  opts.on("--[no-]imap-ssl", "Connect IMAP using SSL") do |o|
    options[:imap_ssl] = o
  end
  
  opts.on("-u", "--imap-username USERNAME", "Connect IMAP with USERNAME") do |o|
    options[:imap_username] = o
  end
  
  opts.on("-p", "--imap-password PASSWORD", "Connect IMAP with PASSWORD") do |o|
    options[:imap_password] = o
  end
  
  opts.on("--imap-mailboxes [INBOX,DEV]", Array, "Read IMAP MAILBOXES") do |o|
    options[:imap_mailboxes] = o
  end
  
  opts.separator ""
  opts.separator "Listener ftp:"
  
  opts.on("-h", "--ftp-host HOST", "Connect FTP with HOST") do |o|
    options[:ftp_host] = o
  end
  
  opts.on("--[no-]ftp-passive", "Connect FTP using PASSIVE mode") do |o|
    options[:ftp_passive] = o
  end
  
  opts.on("-u", "--ftp-username USERNAME", "Connect FTP with USERNAME") do |o|
    options[:ftp_username] = o
  end
  
  opts.on("-p", "--ftp-password PASSWORD", "Connect FTP with PASSWORD") do |o|
    options[:ftp_password] = o
  end
  
  opts.on("--ftp-dirs [dir1,dir2]", Array, "Read FTP DIRS") do |o|
    options[:ftp_dirs] = o
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

[
  :listener,
].each do |o|
  unless options[o]
    raise OptionParser::MissingArgument, "--#{o}"
  end
end


# = Configure

Ryespy.configure do |c|
  c.log_level = 'DEBUG' if options[:verbose]
  
  c.listener = options[:listener]
  
  params = [
    :polling_interval,
    :redis_url,
    :redis_ns_ryespy,
  ]
  
  params.concat case c.listener
  when :imap
    [
      :imap_host,
      :imap_port,
      :imap_ssl,
      :imap_username,
      :imap_password,
      :imap_mailboxes,
    ]
  when :ftp
    [
      :ftp_host,
      :ftp_passive,
      :ftp_username,
      :ftp_password,
      :ftp_dirs,
    ]
  else
    []
  end
  
  params.each { |s| c.send("#{s}=", options[s]) unless options[s].nil? }
end

@logger = Ryespy.logger


# = Main loop

loop do
  Ryespy.check_listener
  
  break unless options[:eternal]
  
  @logger.debug { "Snoring for #{Ryespy.config.polling_interval} s" }
  
  sleep Ryespy.config.polling_interval # sleep awhile (snore)
end
