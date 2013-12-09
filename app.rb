require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

set :database, "sqlite3:///bookings.sqlite3"

class Resource < ActiveRecord::Base
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

	date   = params[:date].present?   ? params[:date]   : Time.now.tomorrow.strftime("%Y-%m-%d")
	limit  = params[:limit].present?  ? params[:limit]  : 30
	status = params[:status].present? ? params[:status] : 'approved'

	valid_date   = date =~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/ ? true : false
	#valid_params = params.keys.collect { |key| key.to_s == ('limit' or 'status' or 'date') ? true : false }

	conditions = [valid_date, limit.to_i > 0, limit.to_i <= 365, status == ('approved' or 'pending' or 'all')]

	if !conditions.all?
		redirect to(not_found)
	end

	end_date = Time.parse(date) + (limit*24*60*60)
	
	hash = {bookings: 'asd', links: [rel: 'self', uri: request.url]}
	JSON.pretty_generate(hash)
end
