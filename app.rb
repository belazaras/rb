require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

set :database, "sqlite3:///bookings.sqlite3"

class Resource < ActiveRecord::Base
end

class Booking < ActiveRecord::Base
end

not_found do
  'Not Found'
end

get '/resources' do
	content_type :json

	links = [rel: 'self', uri: request.url]
	resources = Resource.all.collect do |r|
		{name: r.name, description: r.description, links: [rel: 'self', uri: "#{request.url}/#{r.id}"]}
	end

	hash = {resources: resources, links: links}
	JSON.pretty_generate(hash)
end

get '/resources/:id' do
	begin
		content_type :json
		r = Resource.find(params[:id])
		links = [{rel: 'self', uri: request.url}, {rel: 'bookings', uri: "#{request.url}/bookings"}]
		res = {name: r.name, description: r.description, links: links}
		JSON.pretty_generate(res)

	rescue ActiveRecord::RecordNotFound
		redirect to(not_found)
	end
end

get '/resources/:id/bookings' do
	content_type :json

	date   = params[:date].present?   ? params[:date]   	 : Time.now.tomorrow.strftime("%Y-%m-%d")
	limit  = params[:limit].present?  ? params[:limit].to_i  : 30
	status = params[:status].present? ? params[:status]		 : 'approved'

	valid_date   = date =~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/ ? true : false
	#valid_params = params.keys.collect { |key| key.to_s == ('limit' or 'status' or 'date') ? true : false }

	conditions = [valid_date, limit.to_i > 0, limit.to_i <= 365, ["approved", "pending", "all"].include?(status)]

	if !conditions.all?
		redirect to(not_found)
	end

	end_date = Time.parse(date) + (limit*24*60*60)
	str_start = date.to_s + ' 00:00:00'
	str_end = end_date.strftime("%Y-%m-%d").to_s + ' 23:59:59'

	bks = get_bookings(str_start,str_end,status)
	redirect to(not_found) if bks.empty?

	bookings = bks.collect do |b|
		uri = url("/resources/#{params[:id]}/bookings/#{b.id}")
		b_links = [{rel: 'self', uri: uri}, {rel: 'resource', uri: url("/resources/#{params[:id]}")}, {rel: 'accept', uri: uri, method: 'PUT'}, {rel: 'reject', uri: uri, method: 'DELETE'}]
		{start: b.start, end: b.end, status: b.status, user: b.user, links: b_links}
	end

	hash = {bookings: bookings, links: [{rel: 'self', uri: request.url}]}
	JSON.pretty_generate(hash)
end

def get_bookings(start_d,end_d,status)
	if status == 'all'
		bks = Booking.where("resource_id = :res_id AND start >= :start_date AND end <= :end_date AND status <> 'canceled'",
  		{res_id: params[:id], start_date: start_d, end_date: end_d})
  	else
  		bks = Booking.where("resource_id = :res_id AND start >= :start_date AND end <= :end_date AND status = :status",
  		{res_id: params[:id], start_date: start_d, end_date: end_d, status: status})
  	end
  	return bks
end

get '/resources/:id/availability' do
	content_type :json

	date  = params[:date].present?   ? params[:date]   	 : Time.now.tomorrow.strftime("%Y-%m-%d")
	limit = params[:limit].present?  ? params[:limit].to_i  : 30
	valid_date = date =~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/ ? true : false

	conditions = [valid_date, limit.to_i > 0, limit.to_i <= 365]

	if !conditions.all?
		redirect to(not_found)
	end

	end_date = Time.parse(date) + (limit*24*60*60)
	str_start = date.to_s + ' 00:00:00'
	str_end = end_date.strftime("%Y-%m-%d").to_s + ' 00:00:00'

	avl = get_availability(str_start,str_end)
	#avl.inspect
	hash = {availability: avl, links: [{rel: 'self', uri: request.url}]}
	JSON.pretty_generate(hash)
end

def get_availability(start_d,end_d)
	links = [{rel: 'book', uri: url("/resources/#{params[:id]}/bookings"), method: 'POST'}, {rel: 'resource', uri: url("/resources/#{params[:id]}")}]
	bks = get_bookings(start_d,end_d,'approved')

	return {from: start_d, to: end_d, links: links} if bks.empty?

	ini = start_d
	avl = []
	bks.collect do |b|
		avl << {from: ini, to: b.start, links: links}
		ini = b.end
	end

	avl.pop if avl.last[:to] >= end_d
	avl.push({from: ini, to: end_d, links: links}) if avl.last[:to] < end_d
	avl.shift if start_d == avl.first[:to].to_s
	puts avl.first[:to].to_s
	return avl
end