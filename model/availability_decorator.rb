# encoding: UTF-8
require_relative 'decorator'

# Clase AvailabilityDecorator
class AvailabilityDecorator < Decorator
  def self.plural_name
    'availability'
  end

  def to_hash_plural(url)
    c = @component
    {
      from: c[:from],
      to: c[:to],
      links: [
        {
          rel: "book",
          uri: "#{url}/resources/#{c[:res_id]}/bookings",
          method: "POST"
        },
        {
          rel: "resource",
          uri: "#{url}/resources/#{c[:res_id]}"
        }
      ]
    }
  end
end
