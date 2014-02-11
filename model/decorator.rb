# encoding: UTF-8
# Clase Decorator
class Decorator
  def initialize(component)
    @component = component
  end

  # Redefinido en subclase.
  def to_hash_singular(url); end

  def to_hash_plural(url); end

  def single_name; end

  def self.plural_name; end

  def jsonize(url)
    hash = to_hash_singular(url)
    JSON.pretty_generate(single_name => hash)
  end

  def self.jsonize(collection, request)
    hash = []
    collection.each do |bk|
      hash << new(bk).to_hash_plural(request.base_url)
    end
    JSON.pretty_generate(plural_name => hash, links: links_collection(request.url))
  end

  def self.links_collection(url)
    [{ rel: 'self', uri: url }]
  end
end
