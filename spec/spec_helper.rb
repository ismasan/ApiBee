require 'rubygems'
require 'bundler'

$TESTING = true

Bundler.setup(:default, :test)

$LOAD_PATH.unshift(File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib'))

ENV['RACK_ENV'] = 'test'

require 'api_bee'

RSpec.configure do |config|
  # some (optional) config here
end