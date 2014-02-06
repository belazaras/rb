# encoding: UTF-8
require 'test_helper'

# Clase de Testing
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

  def test_get_nonexistent_page # no va
    get '/error'
    assert_equal 404, last_response.status
    assert_equal 'Not Found', last_response.body
  end

  def test_get_resources# testear q sea json
    get '/resources'
    assert_equal 200, last_response.status
  end

  #testear formato: json expressions

  def test_get_resource
    get '/resources/1'
    assert_equal 200, last_response.status
  end

#testear un id valido pero inexistente, abajo testeo fruta nomas.

  def test_get_nonexistent_resource
    get '/resources/asd'
    assert_equal 404, last_response.status
    assert_equal 'Not Found', last_response.body
  end

# testear resources/id/bookings con id valido, con invalido, y fruta ya esta.
# testear las diferentes combinaciones de parametros validos e invalidos y ver q den lo q corresponda.
# testear q el body y content type sea json si o si.
  def test_get_res_booking_wrong_date
    get '/resources/1/bookings?date=asd'
    assert_equal 404, last_response.status
  end

  def test_get_res_booking_wrong_limit
    get '/resources/1/bookings?limit=asd'
    assert_equal 404, last_response.status
  end

  def test_get_res_booking_wrong_status
    get '/resources/1/bookings?status=asd'
    assert_equal 404, last_response.status
  end

  def test_get_res_bks_bad_parameter
    get '/resources/1/bookings?badparameter=123'
    assert_equal 404, last_response.status
  end

  def test_availability_wrong_date
    get '/resources/1/availability?date=asd'
    assert_equal 404, last_response.status
  end

  def test_availability_wrong_limit
    get '/resources/1/availability?limit=asd'
    assert_equal 404, last_response.status
  end

  def test_add_booking
    post 'resources/asd/bookings', from: '', to: ''
    assert_equal 404, last_response.status

    post 'resources/2/bookings', from: '2013-11-13T11:00:00Z', to: '2013-11-14T11:00:00Z'
    assert_equal 409, last_response.status

    post 'resources/2/bookings', from: '2013-11-13T11:00:00Z', to: '2013-11-14T11:00:00Z'
    assert_equal 409, last_response.status
    post 'resources/2/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
  end

  def test_add_booking_limits
    # Justo donde otra termina.
    post 'resources/2/bookings', from: '2013-11-13T12:00:00Z', to: '2013-11-13T13:00:00Z'
    assert_equal 201, last_response.status

    # Esta termina donde otra empieza.
    post 'resources/2/bookings', from: '2013-11-14T10:00:00Z', to: '2013-11-14T11:00:00Z'
    assert_equal 201, last_response.status

    # Con from en medio de otra aceptada.
    post 'resources/2/bookings', from: '2013-11-13T11:30:00Z', to: '2013-11-13T13:00:00Z'
    assert_equal 409, last_response.status

    # Con to en medio de otra aceptada.
    post 'resources/2/bookings', from: '2013-11-14T10:00:00Z', to: '2013-11-14T11:30:00Z'
    assert_equal 409, last_response.status
  end

  def test_add_same_booking
    post 'resources/2/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
    post 'resources/2/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
  end

  def test_accept_one_cancel_the_others
    post 'resources/2/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    post 'resources/2/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    put "resources/2/bookings/#{bk1.id}"
    bk2 = Booking.last
    assert_equal 'canceled', bk2.status
  end

  def test_accept_nonexistent_booking
    id = 99
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
    id = bk1.id - 1
    put "resources/2/bookings/#{id}"
    assert_equal 200, last_response.status
  end

  def test_accept_canceled_booking
    post 'resources/2/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    id = bk1.id
    delete "resources/2/bookings/#{id}"
    put "resources/2/bookings/#{id}"
    assert_equal 409, last_response.status
  end

  def test_cancel_booking
    post 'resources/2/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    id = bk1.id
    delete "resources/2/bookings/#{id}"
    assert_equal 200, last_response.status
  end

  def test_cancel_nonexistent_booking
    id = 99
    delete "resources/2/bookings/#{id}"
    assert_equal 404, last_response.status
  end
end
