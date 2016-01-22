require 'fun_sftp'

require_relative 'base'


module Ryespy
  module Listener
    class SFTP < Base
      include FunSftp

      REDIS_KEY_PREFIX  = 'sftp'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespySFTPJob'.freeze

      def initialize(opts = {})
        @sftp_config = {
          :host     => opts[:host],
          :port     => opts[:port],
          :username => opts[:username],
          :password => opts[:password]
        }

        super(opts)
      end

      def check(dir)
        @logger.debug { "dir: #{dir}" }

        @logger.debug { "redis_key: #{redis_key(dir)}" }

        seen_files = @redis.hgetall(redis_key(dir))

        unseen_files = get_unseen_files(dir, seen_files)

        @logger.debug { "unseen_files: #{unseen_files}" }

        unseen_files.each do |filename, checksum|
          @redis.hset(redis_key(dir), filename, checksum)

          @notifiers.each { |n| n.notify(SIDEKIQ_JOB_CLASS, [dir, filename]) }
        end

        @logger.info { "#{dir} has #{unseen_files.count} new files" }
      end

      private

      def connect_service
        @sftp =  SFTPClient.new(@sftp_config[:host], @sftp_config[:port], @sftp_config[:username], @sftp_config[:password])
      end

      def redis_key(dir)
        [
          REDIS_KEY_PREFIX,
          @sftp_config[:host],
          @sftp_config[:port],
          @sftp_config[:username],
          dir,
        ].join(':')
      end

      def get_unseen_files(dir, seen_files)
        @sftp.reset_path!
        @sftp.chdir(dir)

        files = {}

        @sftp.entries(".").each do |file|
          mtime = @sftp.mtime(file).to_i
          size = @sftp.size(file) rescue nil # ignore non-file error

          if size # exclude directories
            checksum = "#{mtime},#{size}".freeze

            if seen_files[file] != checksum
              files[file] = checksum
            end
          end
        end

        files
      end

    end
  end
end
