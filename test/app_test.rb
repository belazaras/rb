require 'test_helper'

class AppTest < Minitest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_get_nonexistent_page
    get '/error'
    assert_equal 404, last_response.status
    assert_equal 'Not Found', last_response.body
  end

  def test_get_resources
  	get '/resources'
  	assert_equal 200, last_response.status
  end

  def test_get_resource
  	get '/resources/1'
  	assert_equal 200, last_response.status
  end

  def test_get_nonexistent_resource
    get '/resources/asd'
    assert_equal 404, last_response.status
    assert_equal 'Not Found', last_response.body
  end

  def test_get_resource_bookings
  	get '/resources/1/bookings?date=asd'
  	assert_equal 404, last_response.status
    get '/resources/1/bookings?badparameter=123'
    assert_equal 404, last_response.status
  	get '/resources/1/bookings?limit=asd'
  	assert_equal 404, last_response.status
  	get '/resources/1/bookings?status=asd'
  	assert_equal 404, last_response.status
  end

  def test_add_booking
    post 'resources/asd/bookings', :from => '', :to => ''
    assert_equal 404, last_response.status
    post 'resources/2/bookings', :from => '2013-11-13T11:00:00Z', :to => '2013-11-14T11:00:00Z'
    assert_equal 409, last_response.status
    post 'resources/2/bookings', :from => '2013-11-13T11:00:00Z', :to => '2013-11-14T11:00:00Z'
    assert_equal 409, last_response.status
  end

end
