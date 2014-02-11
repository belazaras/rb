# encoding: UTF-8
ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app', __FILE__
require 'json_expressions/minitest'
require 'database_cleaner'
DatabaseCleaner.strategy = :transaction
ActiveRecord::Base.logger.level = 1

def ini_resource
  Resource.create(
    name: "Computadora",
    description: "Notebook con 4GB de RAM y 256 GB de espacio en disco con Linux"
  )
end

def ini_bookings
  Booking.create(
    start: "2013-11-13 11:00:00", end: "2013-11-13 12:00:00",
    status: "approved", resource_id: 1, user: "martita@gmail.com"
  )
  Booking.create(
    start: "2013-11-13 14:00:00", end: "2013-11-13 15:00:00",
    status: "pending", resource_id: 1, user: "martita@gmail.com"
  )
  Booking.create(
    start: "2013-11-14 11:00:00", end: "2013-11-14 12:00:00",
    status: "approved", resource_id: 1, user: "martita@gmail.com"
  )
end
