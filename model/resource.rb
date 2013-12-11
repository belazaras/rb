class Resource < ActiveRecord::Base

	def to_json
		return @name	
	end
end