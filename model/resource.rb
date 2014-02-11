# encoding: UTF-8
# Clase Resource
class Resource < ActiveRecord::Base
  validates :name, :description, presence: true
  validates :name, length: { maximum: 255 }
end
