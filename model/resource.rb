class Resource < ActiveRecord::Base
	def to_hash link
		return {name: name, description: description, links: [rel: 'self', uri: link+"/resources/#{id}"]}
	end

	def to_json link
		res = self.to_hash link
		res[:links] = [{rel: 'self', uri: link+"/resources/#{id}"}, {rel: 'bookings', uri: link+"/resources/#{id}/bookings"}]
		return JSON.pretty_generate({resource: res})
	end

	def self.to_json link
		links = [rel: 'self', uri: link+"/resources"]

		resources = Resource.all.collect do |r|
			r.to_hash link
		end
		res = {resources: resources, links: links}
		return JSON.pretty_generate(res)
	end
end