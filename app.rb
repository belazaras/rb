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
		r = Resource.find(params[:id])
		links = [{rel: 'self', uri: request.url}, {rel: 'bookings', uri: "#{request.url}/bookings"}]
		res = {name: r.name, description: r.description, links: links}
		JSON.pretty_generate(res)

	rescue ActiveRecord::RecordNotFound
		redirect to(not_found)
	end
end

