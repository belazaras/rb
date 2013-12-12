require 'test_helper'

class AppTest < Minitest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
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

  def test_availability_wrong_params
    get '/resources/1/availability?date=asd'
    assert_equal 404, last_response.status
    get '/resources/1/availability?limit=asd'
    assert_equal 404, last_response.status
  end

  def test_add_booking
    post 'resources/asd/bookings', :from => '', :to => ''
    assert_equal 404, last_response.status
    post 'resources/2/bookings', :from => '2013-11-13T11:00:00Z', :to => '2013-11-14T11:00:00Z'
    assert_equal 409, last_response.status
    post 'resources/2/bookings', :from => '2013-11-13T11:00:00Z', :to => '2013-11-14T11:00:00Z'
    assert_equal 409, last_response.status
    post 'resources/2/bookings', :from => '2013-11-16T11:00:00Z', :to => '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
    #Testing limits:
    post 'resources/2/bookings', :from => '2013-11-13T12:00:00Z', :to => '2013-11-13T13:00:00Z'#Justo donde otra termina.
    assert_equal 201, last_response.status
    post 'resources/2/bookings', :from => '2013-11-14T10:00:00Z', :to => '2013-11-14T11:00:00Z'#Esta termina donde otra empieza.
    assert_equal 201, last_response.status
    post 'resources/2/bookings', :from => '2013-11-13T11:30:00Z', :to => '2013-11-13T13:00:00Z'#Con from en medio de otra aceptada.
    assert_equal 409, last_response.status
    post 'resources/2/bookings', :from => '2013-11-14T10:00:00Z', :to => '2013-11-14T11:30:00Z'#Con to en medio de otra aceptada.
    assert_equal 409, last_response.status

  end

  def test_add_same_booking
    post 'resources/2/bookings', :from => '2013-11-16T11:00:00Z', :to => '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
    post 'resources/2/bookings', :from => '2013-11-16T11:00:00Z', :to => '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
  end

  def test_accept_one_cancel_the_others
    post 'resources/2/bookings', :from => '2013-11-16T11:00:00Z', :to => '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    post 'resources/2/bookings', :from => '2013-11-16T11:00:00Z', :to => '2013-11-16T12:00:00Z'
    put "resources/2/bookings/#{bk1.id}"
    bk2 = Booking.last
    assert_equal 'canceled', bk2.status 
  end

  def test_accept_nonexistent_booking
    bk1 = Booking.last
    id = bk1.id+1
    put "resources/2/bookings/#{id}"
    assert_equal 404, last_response.status
  end

  def test_accept_already_accepted_booking
    bk1 = Booking.last
    id = bk1.id
    put "resources/2/bookings/#{id}"
    assert_equal 409, last_response.status
  end

  def test_accept_pending_booking
    bk1 = Booking.last
    id = bk1.id-1
    put "resources/2/bookings/#{id}"
    assert_equal 200, last_response.status
  end

  def test_accept_canceled_booking
    post 'resources/2/bookings', :from => '2013-11-16T11:00:00Z', :to => '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    id = bk1.id
    delete "resources/2/bookings/#{id}"
    put "resources/2/bookings/#{id}"
    assert_equal 409, last_response.status
  end

  def test_cancel_booking
    post 'resources/2/bookings', :from => '2013-11-16T11:00:00Z', :to => '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    id = bk1.id
    delete "resources/2/bookings/#{id}"
    assert_equal 200, last_response.status
  end

  def test_cancel_nonexistent_booking
    bk1 = Booking.last
    id = bk1.id+1
    delete "resources/2/bookings/#{id}"
    assert_equal 404, last_response.status
  end

end
