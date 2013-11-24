# Ryespy

[![Gem Version](https://badge.fury.io/rb/ryespy.png)](http://badge.fury.io/rb/ryespy)
[![Build Status](https://travis-ci.org/tiredpixel/ryespy.png?branch=master,stable)](https://travis-ci.org/tiredpixel/ryespy)
[![Code Climate](https://codeclimate.com/github/tiredpixel/ryespy.png)](https://codeclimate.com/github/tiredpixel/ryespy)

[Sidekiq](https://github.com/mperham/sidekiq) /
[Resque](https://github.com/resque/resque) IMAP and FTP listener.

Ryespy provides an executable for listening to IMAP mailboxes or FTP folders,
keeps track of what it's seen using [Redis](http://redis.io), and writes
Sidekiq- / Resque-compatible payloads.

Ryespy was inspired by [Redimap](https://github.com/tiredpixel/redimap).
Yes, it's sometimes possible to inspire oneself.
Ryespy with my little eye.

More sleep lost by [tiredpixel](http://www.tiredpixel.com).


## Installation

Install using:

    $ gem install ryespy

These externals are required:

- [Redis](http://redis.io)


## Usage

View the available options:

    $ ryespy --help

It is necessary to specify a listener (IMAP|FTP) and a notifier (Sidekiq).

Check IMAP, queue new email UIDs, and quit (maybe for Cron):

    $ ryespy --listener imap --imap-host mail.example.com --imap-username a@example.com --imap-password helpimacarrot --notifier-sidekiq

Check FTP, queue new file paths, and quit (maybe for Cron):

    $ ryespy --listener ftp --ftp-host ftp.example.com --ftp-username b@example.com --ftp-password helpimacucumber --notifier-sidekiq

IMAP SSL and FTP PASSIVE are also supported.
It's also possible to watch more than one IMAP mailbox or FTP directory.
The `--help` is most helpful.

Use `--eternal` to run eternally (no need for Cron).


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

- Refactoring and testing
- Additional notifiers (e.g. URL ?)
- Additional listeners (e.g. AWS S3, Rackspace Cloud Files ?)

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


## Blessing

May you find peace, and help others to do likewise.


## Licence

© [tiredpixel](http://www.tiredpixel.com) 2013.
It is free software, released under the MIT License, and may be redistributed
under the terms specified in `LICENSE`.
