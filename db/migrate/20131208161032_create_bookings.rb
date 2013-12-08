class CreateBookings < ActiveRecord::Migration
  def change
  	create_table :bookings do |t|
      t.datetime :start
      t.datetime :end, null: true
      t.string :status
      t.string :user
      t.references :resource
	end
	add_index :resources, :id
  end
end
