require 'net/ftp'

require_relative 'base'


module Ryespy
  module Listener
    class FTP < Base

      REDIS_KEY_PREFIX  = 'ftp'.freeze
      SIDEKIQ_JOB_CLASS = 'RyespyFTPJob'.freeze

      def initialize(opts = {})
        @ftp_config = {
          :host     => opts[:host],
          :port     => opts[:port],
          :passive  => opts[:passive],
          :username => opts[:username],
          :password => opts[:password],
        }

        super(opts)
      end

      def close
        @ftp.close
      end

      def check(dir)
        @logger.debug { "dir: #{dir}" }

        @logger.debug { "redis_key: #{redis_key(dir)}" }

        seen_files = @redis.hgetall(redis_key(dir))

        unseen_files = get_unseen_files(dir, seen_files)

        @logger.debug { "unseen_files: #{unseen_files}" }

        unseen_files.each do |key, file_info|
          notifier_args = [file_info[:dir], file_info[:filename]]
          begin
            notifier_args.to_json #try upfront to convert to json
            @redis.hset(redis_key(dir), key, file_info[:checksum])
            @notifiers.each do |n|
              n.notify(SIDEKIQ_JOB_CLASS, notifier_args)
            end
          rescue Encoding::UndefinedConversionError => e
            @logger.debug { "Error processing #{file_info.inspect} (#{e})"}
          end
        end

        @logger.info { "#{dir} has #{unseen_files.count} new files" }
      end

      private

      def connect_service
        @ftp = Net::FTP.new

        @ftp.connect(@ftp_config[:host], @ftp_config[:port])

        @ftp.passive = @ftp_config[:passive]

        @ftp.login(@ftp_config[:username], @ftp_config[:password])
      end

      def redis_key(dir)
        [
          REDIS_KEY_PREFIX,
          @ftp_config[:host],
          @ftp_config[:port],
          @ftp_config[:username],
          dir,
        ].join(':')
      end

      def get_unseen_files(dir, seen_files)
        @ftp.chdir(dir)

        files = {}

        @ftp.nlst.each do |file|
          size = @ftp.size(file) rescue nil #ignore non-file error

          if size # exclude directories
            mtime = @ftp.mtime(file).to_i
            checksum = "#{mtime},#{size}".freeze
            key = Digest::MD5.hexdigest("#{dir}/#{file}")

            if seen_files[key] != checksum
              files[key] = {
                checksum: checksum,
                filename: file,
                dir: dir
              }
            end
          else # check subdirectory
            begin
              _dir = "#{dir}/#{file}"
              unless @ftp.nlst(file).empty?
                _files = get_unseen_files(_dir, seen_files)
                files.merge!(_files)
                @ftp.chdir(dir)
              end
            rescue Net::FTPError => ex
              @logger.error { "Cannot travserse directory '#{_dir}' (#{ex})" }
            end
          end
        end
        files
      end

    end
  end
end
