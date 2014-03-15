# Ryespy

[![Gem Version](https://badge.fury.io/rb/ryespy.png)](http://badge.fury.io/rb/ryespy)
[![Build Status](https://travis-ci.org/tiredpixel/ryespy.png?branch=master,stable)](https://travis-ci.org/tiredpixel/ryespy)
[![Code Climate](https://codeclimate.com/github/tiredpixel/ryespy.png)](https://codeclimate.com/github/tiredpixel/ryespy)

[Sidekiq](https://github.com/mperham/sidekiq)/[Resque](https://github.com/resque/resque)
IMAP, FTP, Amazon S3, Google Cloud Storage, Rackspace Cloud Files listener.

Ryespy provides an executable for listening to
IMAP mailboxes,
FTP folders,
Amazon S3 buckets,
Google Cloud Storage buckets,
or Rackspace Cloud Files containers,
keeps track of what it's seen using [Redis](http://redis.io), and writes
Sidekiq/Resque-compatible payloads.

Ryespy was inspired by [Redimap](https://github.com/tiredpixel/redimap).
Yes, it's sometimes possible to inspire oneself.
Ryespy with my little eye.

More sleep lost by [tiredpixel](http://www.tiredpixel.com).


## Installation

Install using:

    $ gem install ryespy

These externals are required:

- [Redis](http://redis.io)

Listener dependencies are required dynamically. That means that it may be necessary to manually install the indicated gems if you are using that listener. If you are not using that listener, there should be no need to install the dependencies.

- `--listener amzn-s3` :
  
        $ gem install fog -v '~> 1.19'

- `--listener goog-cs` :
  
        $ gem install fog -v '~> 1.19'

- `--listener rax-cf` :
  
        $ gem install fog -v '~> 1.19'

The default Ruby version supported is defined in `.ruby-version`.
Any other versions supported are defined in `.travis.yml`.


## Usage

View the available options:

    $ ryespy --help

It is necessary to specify a listener and at least one notifier. Currently, the only notifier is `--notifier-sidekiq` (this must be specified).

The `--help` is most helpful.

Use `--eternal` to run eternally (no need for Cron).


### IMAP Listener

Check IMAP, queue new email UIDs, and quit (maybe for Cron):

    $ ryespy --listener imap --imap-host mail.example.com --imap-username a@example.com --imap-password helpimacarrot --notifier-sidekiq

For non-SSL, use `--no-imap-ssl`. For non-INBOX or multiple mailboxes, use `--imap-mailboxes INBOX,Sent`.

### FTP Listener

Check FTP, queue new file paths, and quit (maybe for Cron):

    $ ryespy --listener ftp --ftp-host ftp.example.com --ftp-username b@example.com --ftp-password helpimacucumber --notifier-sidekiq

For PASSIVE mode, use `--ftp-passive`. For non-root or multiple directories, use `--ftp-dirs /DIR1,/DIR2`.

### Amazon S3 Listener

Check Amazon S3, queue new file keys, and quit (maybe for Cron):

    $ ryespy --listener amzn-s3 --amzn-s3-access-key c/example/com --amzn-s3-secret-key helpimabroccoli --amzn-s3-bucket vegetable-box --notifier-sidekiq

For non-* or multiple key prefix filters, use `--amzn-s3-prefixes virtual-dir1/,virtual-dir`.

### Google Cloud Storage Listener

Check Google Cloud Storage, queue new file keys, and quit (maybe for Cron):

    $ ryespy --listener goog-cs --goog-cs-access-key d/example/com --goog-cs-secret-key helpimanasparagus --goog-cs-bucket vegetable-box --notifier-sidekiq

For non-* or multiple key prefix filters, use `--goog-cs-prefixes virtual-dir1/,virtual-dir`.

### Rackspace Cloud Files Listener

Check Rackspace Cloud Files, queue new file keys, and quit (maybe for Cron):

    $ ryespy --listener rax-cf --rax-cf-username vegetable --rax-cf-api-key helpimacelery --rax-cf-container vegetable-box --notifier-sidekiq

For non-DFW region, use `--rax-cf-region lon`. For non-US auth endpoint, use `--rax-cf-endpoint uk`. Is your Rackspace account in London? Fret not; combine these and use `--rax-cf-endpoint uk --rax-cf-region lon`. For non-* or multiple key prefix filters, use `--rax-cf-prefixes virtual-dir1/,virtual-dir`.


## Advanced Usage

If you want to do something rather more magical, such as checking multiple accounts for a listener or even multiple listeners, then you may wish to use the Ryespy library directly instead of the `ryespy` executable.

Depend upon the `ryespy` gem in a `Gemfile`, remembering to add any manual dependencies for listeners as detailed in [Installation](#installation):

    # Gemfile
    
    gem 'ryespy'
    gem 'fog' # example manual dependency

Configure Ryespy Redis and require Ryespy:

    require 'redis'
    require 'redis/namespace'
    
    Redis.current = Redis::Namespace.new('ryespy',
      :redis => Redis.connect(:url => nil) # Redis default
    )
    
    require 'ryespy'

Create the notifiers:

    require 'ryespy/notifier/sidekiq'
    
    notifiers = []
    notifiers << Ryespy::Notifier::Sidekiq.new(
      :url       => nil, # Redis default
      :namespace => 'resque'
    )

For each listener, configure like in `ryespy --help` but without the listener prefix and with `-` changed to `_` (e.g. `--amzn-s3-access-key` => `:access_key`). Pass in an array of notifiers. Note that the `check()` argument varies per listener, meaning IMAP mailbox, FTP directory, or storage key prefix.

    require 'ryespy/listener/amzn_s3'
    
    Ryespy::Listener::AmznS3.new(
      :access_key => 'ACCESS_KEY',
      :secret_key => 'SECRET_KEY',
      :bucket     => 'BUCKET',
      :notifiers  => notifiers
    ) do |listener|
      listener.check('prefix/')
    end

That's about the size of it.


## Stay Tuned

We have a [Librelist](http://librelist.com) mailing list!
To subscribe, send an email to <ryespy@librelist.com>.
To unsubscribe, send an email to <ryespy-unsubscribe@librelist.com>.
There be [archives](http://librelist.com/browser/ryespy/).
That was easy.

You can also become a [watcher](https://github.com/tiredpixel/ryespy/watchers)
on GitHub. And don't forget you can become a [stargazer](https://github.com/tiredpixel/ryespy/stargazers) if you are so minded. :D


## Growing Like Flowers

Dear Me, Here is a vague wishlist:

- Additional notifiers (e.g. URL ?)

Also take a look at the [issue tracker](https://github.com/tiredpixel/ryespy/issues).


## Contributions

Contributions are embraced with much love and affection!
Please fork the repository and wizard your magic, preferably with plenty of
fairy-dust sprinkled over the tests. ;)
Then send me a pull request. Simples!
If you'd like to discuss what you're doing or planning to do, or if you get
stuck on something, then just wave. :)

Do whatever makes you happy. We'll probably still like you. :)

Tests are written using [minitest](https://github.com/seattlerb/minitest),
which is included by default in Ruby 1.9 onwards. To run all tests:

    rake test

When using the `ryespy` executable in development, you'll probably want to set `--debug` mode so debug-level messages are logged and stack traces raised.


## Blessing

May you find peace, and help others to do likewise.


## Licence

© [tiredpixel](http://www.tiredpixel.com) 2013.
It is free software, released under the MIT License, and may be redistributed
under the terms specified in `LICENSE`.
