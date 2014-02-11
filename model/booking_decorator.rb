# encoding: UTF-8
require_relative 'decorator'

# Clase BookingDecorator
class BookingDecorator < Decorator
  def single_name
    'book'
  end

  def self.plural_name
    'bookings'
  end

  def to_hash_singular(url)
    c = @component
    {
      start: @component.start,
      end: @component.end,
      status: @component.status,
      user: @component.user,
      links: [
        {
          rel: "self",
          uri: "#{url}/resource/#{c.resource_id}/bookings/#{c.id}"
        },
        {
          rel: "accept",
          uri: "#{url}/resource/#{c.resource_id}/bookings/#{c.id}",
          method: "PUT"
        },
        {
          rel: "reject",
          uri: "#{url}/resource/#{c.resource_id}/bookings/#{c.id}",
          method: "DELETE"
        }
      ]
    }
  end

  def to_hash_plural(url)
    c = @component
    {
      start: @component.start,
      end: @component.end,
      status: @component.status,
      user: @component.user,
      links: [
        {
          rel: "self",
          uri: "#{url}/resource/#{c.resource_id}/bookings/#{c.id}"
        },
        {
          rel: "resource",
          uri: "#{url}/resources/#{c.resource_id}"
        },
        {
          rel: "accept",
          uri: "#{url}/resource/#{c.resource_id}/bookings/#{c.id}",
          method: "PUT"
        },
        {
          rel: "reject",
          uri: "#{url}/resource/#{c.resource_id}/bookings/#{c.id}",
          method: "DELETE"
        }
      ]
    }
  end
end
