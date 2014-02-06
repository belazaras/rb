# encoding: UTF-8
# Clase Booking
class Booking < ActiveRecord::Base
  def to_hash(link)
    uri = link + "/resources/#{resource_id}/bookings/#{id}"
    b_links = [
      { rel: 'self', uri: uri },
      { rel: 'resource', uri: link + "/resources/#{resource_id}" },
      { rel: 'accept', uri: uri, method: 'PUT' },
      { rel: 'reject', uri: uri, method: 'DELETE' }
    ]
    { from: start, to: self.end, status: status, links: b_links }
  end

  def to_json(link)
    res = to_hash link
    JSON.pretty_generate(book: res)
  end
end
