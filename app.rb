# encoding: UTF-8
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym
require 'sinatra/reloader'
require_relative 'model/resource'
require_relative 'model/resource_decorator'
require_relative 'model/booking'
require_relative 'model/booking_decorator'
require_relative 'model/availability_decorator'
require_relative 'lib/validator'

set :database, 'sqlite3:///bookings.sqlite3'
#set :database, 'sqlite3:///bookings-ASD.sqlite3'
# ActiveRecord::Base.logger.level = 1
# set :dump_errors, false
disable :raise_errors
disable :show_exceptions

error ActiveRecord::RecordNotFound do
  status 404
  'Not Found'
end

# error ArgumentError do
#   status 409
#   'Error'
# end

##################################
# get '/borrar' do
#   bd = BookingDecorator.new(Booking.find(5)).jsonize(request.base_url)

#   #bks = Booking.where("resource_id = :res_id",res_id: 2)
#   #bks = []
#   #BookingDecorator.jsonize(bks, request)

#   #res_d = ResourceDecorator.new(Resource.find(1)).jsonize(request.base_url)

#   #bks = Resource.all
#   #bks = []
#   #ResourceDecorator.jsonize(bks, request)

#   avl = [{ from: "PEPE", to: "CACA", res_id: '1'}, { from: "PEPE", to: "CACA", res_id: '1'}]
#   AvailabilityDecorator.jsonize(avl, request)
# end
##################################

error do
  status 409
  'Error'
end

not_found do
  'Not Found'
end

before do
  content_type :json
end

get '/resources' do
  Resource.to_json request.base_url
end

get '/resources/:id' do
  Integer(params[:id])
  Resource.find(params[:id]).to_json request.base_url
end

get '/resources/:id/bookings' do
  date = getter_date
  limit  = getter_limit
  status = params[:status].present? ? params[:status] : 'approved'

  conditions = [
    Validator.valid_date(date),
    Validator.valid_limit(limit),
    Validator.valid_status(status),
    Validator.valid_params(params, %w(id date limit status splat captures))
  ]
  redirect to(error) unless conditions.all?

  end_date = Time.parse(date) + (limit * 24 * 60 * 60)
  str_start = date.to_s + ' 00:00:00'
  str_end = end_date.strftime('%Y-%m-%d').to_s + ' 23:59:59'

  bks = get_bookings(params[:id], str_start, str_end, status)

  links = [{ rel: 'self', uri: request.url }]

  empty = { bookings: [], links: links }
  
  # Usado para cortar el flujo de control.
  return JSON.pretty_generate(empty) if bks.empty?

  bookings = bks.map do |b|
    b.to_hash request.base_url
  end

  hash = { bookings: bookings, links: links }
  JSON.pretty_generate(hash)
end

get '/resources/:id/availability' do
  date = getter_date
  limit = getter_limit

  conditions = [
    Validator.valid_date(date), Validator.valid_limit(limit),
    Validator.valid_params(params, %w(id date limit splat captures))
  ]
  redirect to(error) unless conditions.all?

  end_date = Time.parse(date) + (limit * 24 * 60 * 60)
  str_start = date.to_s + ' 00:00:00'
  str_end = end_date.strftime('%Y-%m-%d').to_s + ' 00:00:00'

  Resource.find(params[:id])

  avl = get_availability(params[:id], str_start, str_end)
  hash = { availability: avl, links: [{ rel: 'self', uri: request.url }] }
  JSON.pretty_generate(hash)
end

post '/resources/:id/bookings' do
  # Testea el formato:
  Time.iso8601(params[:from])
  Time.iso8601(params[:to])

  from = params[:from]
  to = params[:to]
  redirect to(error) if from >= to

  # Que el recurso exista:
  id = params[:id]
  Resource.find(id)

  avl = get_availability(id, from, to)
  redirect to(error) if avl.count != 1
  redirect to(error) if avl.first[:from] != from

  status 201
  bk = Booking.create(
    start: from, end: to, resource_id: id, status: 'pending',
    user: 'no_se_pide_en_el_post@gmail.com'
  ).to_hash request.base_url

  bk[:links].delete_at 1
  JSON.pretty_generate(book: bk)
end

delete '/resources/:id/bookings/:bkid' do
  bk = Booking.find(params[:bkid])
  bk.status = 'canceled'
  bk.save
  status 200
end

put '/resources/:id/bookings/:bkid' do
  bk = Booking.find(params[:bkid])
  redirect to(error) if bk.resource_id.to_s != params[:id]

  avl = get_availability(params[:id], bk.start.iso8601 , bk.end.iso8601)
  redirect to(error) if avl.count != 1
  redirect to(error) if avl.first[:from] != bk.start.iso8601
  redirect to(error) if bk.status != 'pending'

  bk.status = 'approved'
  bk.save

  bks = get_bookings(bk.resource_id, bk.start, bk.end, 'pending')
  bks.each do |b|
    b.status = 'canceled'
    b.save
  end

  bk.to_json request.base_url
end

get '/resources/:id/bookings/:bkid' do
  bk = Booking.find(params[:bkid])
  bk.to_json request.base_url
end

def tomorrow
  Time.now.tomorrow.strftime('%Y-%m-%d')
end

def getter_limit
  params[:limit].present? ? params[:limit].to_i : 30
end

def getter_date
  params[:date].present? ? params[:date] : tomorrow
end

def parse_date(date)
  Time.parse(date).strftime('%Y-%m-%d %H:%M:%S')
end

def get_8601_date(date)
  Time.parse(date + ' UTC').iso8601
end

def get_bookings(res_id, start_d, end_d, status)
  all_exp = "resource_id = :res_id AND status <> 'canceled' AND
    start <= :end_date AND end > :start_date"
  else_exp = "resource_id = :res_id AND status = :status AND
    start <= :end_date AND end > :start_date"
  use = status == 'all' ? all_exp : else_exp
  Booking.where(
    use,
    res_id: res_id, start_date: start_d,
    end_date: end_d, status: status
  )
end

def get_availability(res_id, start_d, end_d)
  links = [
    {
      rel: 'book', uri: url("/resources/#{params[:id]}/bookings"),
      method: 'POST'
    },
    {
      rel: 'resource', uri: url("/resources/#{params[:id]}")
    }
  ]

  start_normal = parse_date(start_d)
  end_normal = parse_date(end_d)
  start_8601 = get_8601_date(start_d)
  end_8601 = get_8601_date(end_d)

  bks = get_bookings(res_id, start_normal, end_normal, 'approved')
  # Usado para cortar el flujo de control.
  return [{ from: start_8601, to: end_8601, links: links }] if bks.empty?

  ini = start_8601
  avl = []
  bks.map do |b|
    avl << { from: ini, to: b.start, links: links }
    ini = b.end
  end

  avl.pop if avl.last[:to] >= end_8601

  if !avl.empty? && avl.last[:to] < end_8601
    avl.push(from: ini, to: end_8601, links: links)
  end

  avl.shift if !avl.empty? && start_d >= bks.first[:start].to_s
  avl
end
