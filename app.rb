# encoding: UTF-8
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym
require 'sinatra/reloader'
require_relative 'model/resource'
require_relative 'model/booking'
set :database, 'sqlite3:///bookings.sqlite3'

not_found do
  'Not Found'
end

get '/resources' do
  content_type :json
  Resource.to_json request.base_url
end

get '/resources/:id' do
  begin
    content_type :json
    Resource.find(params[:id]).to_json request.base_url
  rescue ActiveRecord::RecordNotFound
    redirect to(not_found)
  end
end

get '/resources/:id/bookings' do
  content_type :json

  date =
    params[:date].present? ? params[:date] :
    Time.now.tomorrow.strftime('%Y-%m-%d')
  limit  = params[:limit].present? ? params[:limit].to_i : 30
  status = params[:status].present? ? params[:status] : 'approved'

  valid_date =
    date =~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/ ? true :
    false

  valid_params =
    params.keys.map do |k|
      %w(id date limit status splat captures).include?(k.to_s)
    end

  conditions = [valid_date, limit.to_i > 0, limit.to_i <= 365, %w(
    approved pending all
  ).include?(status), valid_params.all?]

  redirect to(not_found) unless conditions.all?

  end_date = Time.parse(date) + (limit * 24 * 60 * 60)
  str_start = date.to_s + ' 00:00:00'
  str_end = end_date.strftime('%Y-%m-%d').to_s + ' 23:59:59'

  bks = get_bookings(params[:id], str_start, str_end, status)

  links = [{ rel: 'self', uri: request.url }]

  empty = { bookings: [], links: links }
  return JSON.pretty_generate(empty) if bks.empty?

  bookings = bks.map do |b|
    b.to_hash request.base_url
  end

  hash = { bookings: bookings, links: links }
  JSON.pretty_generate(hash)
end

def get_bookings(res_id, start_d, end_d, status)
  if status == 'all'
    bks = Booking.where(
      "resource_id = :res_id AND status = <> 'canceled' AND
      start <= :end_date AND end > :start_date",
      res_id: res_id,
      start_date: start_d,
      end_date: end_d
    )
  else
    bks = Booking.where(
      "resource_id = :res_id AND status = :status AND
      start <= :end_date AND end > :start_date",
      res_id: res_id,
      start_date: start_d,
      end_date: end_d,
      status: status
    )
  end
  bks
end

get '/resources/:id/availability' do
  content_type :json

  d = params[:date]
  date = d.present? ? d : Time.now.tomorrow.strftime('%Y-%m-%d')
  limit = params[:limit].present? ? params[:limit].to_i : 30
  valid_date =
    date =~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/
  valid_params =
    params.keys.map { |k| %w(id date limit splat captures).include?(k.to_s) }

  conditions = [
    valid_date, limit.to_i > 0, limit.to_i <= 365, valid_params.all?
  ]

  redirect to(not_found) unless conditions.all?

  end_date = Time.parse(date) + (limit * 24 * 60 * 60)
  str_start = date.to_s + ' 00:00:00'
  str_end = end_date.strftime('%Y-%m-%d').to_s + ' 00:00:00'

  begin
    Resource.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect to(not_found)
  end

  avl = get_availability(params[:id], str_start, str_end)
  hash = { availability: avl, links: [{ rel: 'self', uri: request.url }] }
  JSON.pretty_generate(hash)
end

# ver esto:
error ActiveRecord::RecordNotFound do |error|
  'error'
  redirect to(not_found)
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

  bks = get_bookings(res_id, start_d, end_d, 'approved')
  return [{ from: start_d, to: end_d, links: links }] if bks.empty?

  ini = start_d
  avl = []
  bks.map do |b|
    avl << { from: ini, to: b.start, links: links }
    ini = b.end
  end

  avl.pop if avl.last[:to] >= end_d

  if !avl.empty? && avl.last[:to] < end_d
    avl.push(from: ini, to: end_d, links: links)
  end

  avl.shift if !avl.empty? && start_d >= avl.first[:from].to_s
  avl
end

get '/test' do
  content_type :json
  from = Time.parse('2013-11-14T10:00:00Z').strftime('%Y-%m-%d %H:%M:%S')
  to = Time.parse('2013-11-14T11:00:00Z').strftime('%Y-%m-%d %H:%M:%S')
  avl = get_availability 2, from, to
  avl.inspect
end

post '/resources/:id/bookings' do
  content_type :json
  begin
    Time.iso8601(params[:from])
    Time.iso8601(params[:to])
  rescue ArgumentError
    redirect to(not_found)
  end

  from = Time.parse(params[:from]).strftime('%Y-%m-%d %H:%M:%S')
  to = Time.parse(params[:to]).strftime('%Y-%m-%d %H:%M:%S')

  redirect to(not_found) if from >= to
  id = params[:id]
  begin
    Resource.find(id)
  rescue ActiveRecord::RecordNotFound
    redirect to(not_found)
  end

  avl = get_availability id, from, to
  return status 409 if avl.count != 1
  return status 409 if avl.first[:from] != from

  status 201
  bk = Booking.create(
    start: from, end: to, resource_id: id, status: 'pending',
    user: 'no_se_pide_en_el_post@gmail.com'
  ).to_hash request.base_url

  bk[:links].delete_at 1
  JSON.pretty_generate(book: bk)
end

delete '/resources/:id/bookings/:bkid' do
  begin
    bk = Booking.find(params[:bkid])
  rescue ActiveRecord::RecordNotFound
    redirect to(not_found)
  end

  bk.status = 'canceled'
  bk.save
  status 200
end

put '/resources/:id/bookings/:bkid' do
  content_type :json
  begin
    bk = Booking.find(params[:bkid])
  rescue ActiveRecord::RecordNotFound
    redirect to(not_found)
  end

  avl = get_availability params[:id], bk.start, bk.end
  return status 409 if avl.count != 1
  return status 409 if avl.first[:from] != bk.start
  return status 409 if bk.status != 'pending'

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
  content_type :json
  begin
    bk = Booking.find(params[:bkid])
  rescue ActiveRecord::RecordNotFound
    redirect to(not_found)
  end

  bk.to_json request.base_url
end
