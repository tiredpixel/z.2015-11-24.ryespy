# Ryespy

[![Gem Version](https://badge.fury.io/rb/ryespy.png)](http://badge.fury.io/rb/ryespy)
[![Build Status](https://travis-ci.org/tiredpixel/ryespy.png?branch=master,stable)](https://travis-ci.org/tiredpixel/ryespy)
[![Code Climate](https://codeclimate.com/github/tiredpixel/ryespy.png)](https://codeclimate.com/github/tiredpixel/ryespy)

Ryespy provides a simple executable for listening to IMAP mailboxes or FTP
folders, keeps track of what it's seen using Redis, and notifies Redis in a way
in which [Resque](https://github.com/resque/resque) and
[Sidekiq](https://github.com/mperham/sidekiq) can process using workers.

Ryespy was inspired by [Redimap](https://github.com/tiredpixel/redimap). Yes,
it's sometimes possible to inspire oneself. Ryespy with my little eye.

More sleep lost by [tiredpixel](http://www.tiredpixel.com).


## Installation

Install using:

    $ gem install ryespy


## Usage

View the available options:

    $ bundle exec ryespy --help

It is necessary to choose a listener (IMAP|FTP) and a notifier (Sidekiq).

Check IMAP and queue new emails and quit:

    $ bundle exec ryespy --listener imap --imap-host mail.example.com --imap-username a@example.com --imap-password helpimacarrot --notifier-sidekiq

Check FTP and queue new files and quit:

    $ bundle exec ryespy --listener ftp --ftp-host ftp.example.com --ftp-username b@example.com --ftp-password helpimacucumber --notifier-sidekiq

IMAP SSL and FTP PASSIVE are also supported. It's also possible to watch more
than one IMAP mailbox or FTP directory. The `--help` is most helpful.

Use `--eternal` to run eternally.


## Growing Like Flowers

Coming soon is a grand refactor sprinkled with lots of testing, ensuring that
present code is stable. Then, something or other else. Like a URL notifier.
Or maybe more listeners. Stay tuned -- or better still, help with the tuning.


## Contributions

Contributions are embraced with much love and affection! Please fork the
repository and wizard your magic, ensuring that any tests are not broken by the
changes. Then send a pull request. Simples! If you'd like to discuss what you're
doing or planning to do, or if you get stuck on something, then just wave. :)

Do whatever makes you happy. We'll probably still like you. :)

Tests are written using [minitest](https://github.com/seattlerb/minitest), which
is included by default in Ruby 1.9 onwards. To run all tests:

    rake test

Or, if you're of that turn of mind, use [TURN](https://github.com/TwP/turn)
(`gem install turn`):

    turn test/


## Blessing

May you find peace, and help others to do likewise.


## Licence

© [tiredpixel](http://www.tiredpixel.com) 2013. It is free software, released
under the MIT License, and may be redistributed under the terms specified in
`LICENSE`.
