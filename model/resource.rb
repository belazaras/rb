# encoding: UTF-8
# Clase Resource
class Resource < ActiveRecord::Base

  # agregar validaciones basicas (q tenga nombre, unico)
  def to_hash(link)
    {
      name: name, description: description,
      links: [rel: 'self', uri: link + "/resources/#{id}"]
    }
  end

  def to_json(link)
    res = to_hash link
    res[:links] = [
      { rel: 'self', uri: link + "/resources/#{id}" },
      { rel: 'bookings', uri: link + "/resources/#{id}/bookings" }
    ]
    JSON.pretty_generate(resource: res)
  end

  def self.to_json(link)
    links = [rel: 'self', uri: link + '/resources']

    resources = Resource.all.map do |r|
      r.to_hash link
    end
    res = { resources: resources, links: links }
    JSON.pretty_generate(res)
  end
end
