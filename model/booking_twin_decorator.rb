# encoding: UTF-8
require_relative 'decorator'

# Clase BookingTwinDecorator
class BookingTwinDecorator < BookingDecorator
  def to_hash_singular(url)
    c = @component
    {
      from: @component.start,
      to: @component.end,
      status: @component.status,
      user: @component.user,
      links: [
        {
          rel: "self",
          uri: "#{url}/resources/#{c.resource_id}/bookings/#{c.id}"
        },
        {
          rel: "resource",
          url: "#{url}/resources/#{c.id}"
        },
        {
          rel: "accept",
          uri: "#{url}/resources/#{c.resource_id}/bookings/#{c.id}",
          method: "PUT"
        },
        {
          rel: "reject",
          uri: "#{url}/resources/#{c.resource_id}/bookings/#{c.id}",
          method: "DELETE"
        }
      ]
    }
  end
end
