require_relative 'ryespy/version'

require_relative 'ryespy/app'

# ryespy/listener/X dynamically required in ryespy/app.rb

require_relative 'ryespy/notifier/sidekiq'
