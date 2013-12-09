require 'time'
text = "2011-05-2689"
parsed = text =~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/ ? true : false
puts parsed

limit = 2
puts Time.now + (limit*24*60*60)