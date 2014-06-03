# Ryespy Changelog

This changelog documents the main changes between released versions.
For a full list of changes, consult the commit history.


## 1.1.0

- start of support for Ruby 2.1.1
- start of support for Ruby 2.1.2
- improved `README` with workers examples
- [#1] new Google Drive listener (`--listener goog-drv`) (thank you, @Lewis-Clayton)
- extension of [#1] with changes detection and tests


## 1.0.0

- first major release; Redis key structure frozen
- Redis key structure backwards-incompatible with 0.x.x (sorry! :( )
- start of support for Ruby 2.1.0
- end of support for Ruby 1.9.2
- new Amazon S3 listener (`--listener amzn-s3`)
- new Google Cloud Storage listener (`--listener goog-cs`)
- new Rackspace Cloud Files listener (`--listener rax-cf`)
- change of `--verbose` mode to `--debug` mode
- broader error-catching, in case weird things happen when `--eternal`
- missing FTP listener (`--listener ftp`) `--ftp-port` fix
- dynamic requiring of listeners (some have their own dependencies)
- comprehensive `README` with lots of examples
- major refactoring and improvement of code throughout
- a plethora of tests; most of the core is now covered
