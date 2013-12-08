require 'bundler'
Bundler.require

set :database, "sqlite3:///../bookings.sqlite3"

class Resource < ActiveRecord::Base
end

u = Resource.all
puts u.inspect
