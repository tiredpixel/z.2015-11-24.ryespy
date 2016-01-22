# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ryespy/version'

Gem::Specification.new do |spec|
  spec.name          = "ryespy"
  spec.version       = Ryespy::VERSION
  spec.authors       = ["tiredpixel"]
  spec.email         = ["tiredpixel@posteo.de"]
  spec.summary       = %q{Redis Sidekiq/Resque IMAP, FTP, SFTP, Amazon S3, Google Cloud Storage, Google Drive, Rackspace Cloud Files listener.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/tiredpixel/ryespy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "redis", "~> 3.0"
  spec.add_dependency "redis-namespace", "~> 1.4"

  spec.add_development_dependency "bundler", "~> 1.3", "!= 1.5.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "fog", "~> 1.19" # conditional dependency
  spec.add_development_dependency "mocha", "~> 0.14"
  spec.add_development_dependency "sidekiq-spy", ">= 0.3.2"
  spec.add_development_dependency "google_drive", '~> 0.3'
end
