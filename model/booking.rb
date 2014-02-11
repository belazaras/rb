# encoding: UTF-8
# Clase Booking
class Booking < ActiveRecord::Base
  validates :start, :end, :status, :user, :resource_id, presence: true
  validates :user, length: { maximum: 255 }
end
