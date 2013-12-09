require 'bundler'
Bundler.require

set :database, "sqlite3:///../bookings.sqlite3"

class Booking < ActiveRecord::Base
end

date = '2013-11-14 11:00:00'
end_date = '2013-11-14 12:00:00'

b = Booking.new(start:date,end: end_date, status:'approved',user:'martita@gmail.com',resource_id: 1)
b.save
puts b.inspect
