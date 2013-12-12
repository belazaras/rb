ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app', __FILE__
require 'database_cleaner'
DatabaseCleaner.strategy = :transaction
