# encoding: UTF-8
require 'sinatra/reloader'
require_relative 'model/resource'
require_relative 'model/resource_decorator'
require_relative 'model/booking'
require_relative 'model/booking_decorator'
require_relative 'model/booking_twin_decorator'
require_relative 'model/availability_decorator'
require_relative 'lib/validator'

set :database, 'sqlite3:///bookings.sqlite3'

# ActiveRecord::Base.logger.level = 1
# set :dump_errors, false
disable :raise_errors
disable :show_exceptions
