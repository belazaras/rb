# encoding: UTF-8
require_relative 'decorator'

# Clase ResourceDecorator
class ResourceDecorator < Decorator
  def single_name
    'resource'
  end

  def self.plural_name
    'resources'
  end

  def to_hash_singular(url)
    c = @component
    {
      name: "#{c.name}",
      description: "#{c.description}",
      links: [
        {
          rel: "self",
          uri: "#{url}/resources/#{c.id}"
        },
        {
          rel: "bookings",
          uri: "#{url}/resources/#{c.id}/bookings"
        }
      ]
    }
  end

  def to_hash_plural(url)
    c = @component
    {
      name: "#{c.name}",
      description: "#{c.description}",
      links: [
        {
          rel: "self",
          uri: "#{url}/resources/#{c.id}"
        }
      ]
    }
  end
end
