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

  def test_get_resources
    get '/resources'
    assert_equal 200, last_response.status
  end

  def test_resources_empty
    server_response = get '/resources'
    pattern = {
      resources: [
      ],
      links: [
        {
          rel: "self",
          uri: /.+\/resources$/
        }
      ]
    }

    assert_json_match(pattern, server_response.body)
    assert_equal 'application/json;charset=utf-8', last_response.headers['Content-Type']
  end

  def test_resources_content
    ini_resource

    server_response = get '/resources'
    pattern = {
      resources: [
        {
          name: String,
          description: String,
          links: [
            {
              rel: "self",
              uri: /.+\/resources\/\d+$/
            }
          ]
        }
      ],
      links: [
        {
          rel: "self",
          uri: /.+\/resources$/
        }
      ]
    }

    assert_json_match(pattern, server_response.body)
    assert_equal 'application/json;charset=utf-8', last_response.headers['Content-Type']
  end

  def test_get_resource
    ini_resource

    get '/resources/1'
    assert_equal 200, last_response.status
  end

  def test_one_resource_content
    ini_resource

    server_response = get '/resources/1'

    pattern = {
      resource: {
        name: String,
        description: String,
        links: [
          {
            rel: "self",
            uri: /.+\/resources\/1$/
          },
          {
            rel: "bookings",
            uri: /.+\/resources\/1\/bookings$/
          }
        ]
      }
    }

    assert_json_match(pattern, server_response.body)
  end

  def test_get_nonexistent_resource
    get '/resources/99'
    assert_equal 404, last_response.status
    assert_equal 'Not Found', last_response.body
  end

  def test_get_invalid_resource
    get '/resources/asd'
    assert_equal 409, last_response.status
    assert_equal 'Error', last_response.body
  end

  # testeo de resources/:id/bookings y resources/:id/availability con id valido, con invalido.
  # testeo de las diferentes combinaciones de parametros validos e invalidos.
  # TODOS ESTOS
  # date
  # limit
  # status
  # !date
  # !limit
  # !status
  # date+limit
  # date+limit+status
  # limit+status
  # date+status
  # !date+limit
  # !date+limit+status
  # !limit+status
  # !date+status

  # Test basico, testea status code y content-type, despues
  # otro testea el contenido del json.
  # No creo que sean muy inteligentes pero bueno.

  def get_sth_good_params(uri, params)
    dir = uri + '?'
    params.each do |one|
      dir << one + '&'
    end
    dir = dir.chomp('&')

    get dir

    assert_equal 200, last_response.status
    assert_equal 'application/json;charset=utf-8', last_response.headers['Content-Type']
  end

  def test_bookings_good_params
    tests = [
      %w(date=2013-11-13), %w(limit=1), %w(status=approved),
      %w(date=2013-11-13 limit=1), %w(date=2013-11-13 limit=1 status=approved),
      %w(date=2013-11-13 status=approved), %w(limit=1 status=approved)
    ]
    tests.each do |one|
      get_sth_good_params('/resources/1/bookings', one)
    end
  end

  def test_availability_good_params
    tests = [
      %w(date=2013-11-13), %w(limit=1), %w(date=2013-11-13 limit=1),
      %w(date=2013-11-13 status=approved)
    ]
    tests.each do |one|
      get_sth_good_params('/resources/1/bookings', one)
    end
  end

  def test_resource_bookings_content
    ini_bookings

    server_response =
      get '/resources/1/bookings?date=2013-11-12&limit=1&status=approved'

    pattern = {
      bookings: [
        {
          from: "2013-11-13T11:00:00Z",
          to: "2013-11-13T12:00:00Z",
          status: "approved",
          user: "martita@gmail.com",
          links: [
            {
              rel: "self",
              uri: /.+\/resources\/1\/bookings\/1$/
            },
            {
              rel: "resource",
              uri: /.+\/resources\/1$/
            },
            {
              rel: "accept",
              uri: /.+\/resources\/1\/bookings\/1$/,
              method: "PUT"
            },
            {
              rel: "reject",
              uri: /.+\/resources\/1\/bookings\/1$/,
              method: "DELETE"
            }
          ]
        }
      ],
      links: [
        {
          rel: "self",
          uri: /.+\/resources\/1\/bookings\?date=2013-11-12&limit=1&status=approved$/
        }
      ]
    }

    assert_json_match(pattern, server_response.body)
  end

  def test_resource_availability_content
    ini_resource
    ini_bookings

    server_response =
      get '/resources/1/availability?date=2013-11-12&limit=3'

    pattern = {
      availability: [
        {
          from: "2013-11-12T00:00:00Z",
          to: "2013-11-13T11:00:00Z",
          links: [
            {
              rel: "book",
              uri: /.+\/resources\/1\/bookings$/,
              method: "POST"
            },
            {
              rel: "resource",
              uri: /.+\/resources\/1$/
            }
          ]
        },
        {
          from: "2013-11-13T12:00:00Z",
          to: "2013-11-14T11:00:00Z",
          links: [
            {
              rel: "book",
              uri: /.+\/resources\/1\/bookings$/,
              method: "POST"
            },
            {
              rel: "resource",
              uri: /.+\/resources\/1$/
            }
          ]
        },
        {
          from: "2013-11-14T12:00:00Z",
          to: "2013-11-15T00:00:00Z",
          links: [
            {
              rel: "book",
              uri: /.+\/resources\/1\/bookings$/,
              method: "POST"
            },
            {
              rel: "resource",
              uri: /.+\/resources\/1$/
            }
          ]
        }
      ],
      links: [
        {
          rel: "self",
          uri: /.+\/resources\/1\/availability\?date=2013-11-12&limit=3$/
        }
      ]
    }

    assert_json_match(pattern, server_response.body)
  end

  def get_sth_wrong_params(uri, params)
    dir = uri + '?'
    params.each do |one|
      dir << one + '=asd&'
    end
    dir = dir.chomp('&')

    get dir
    assert_equal 409, last_response.status
  end

  def test_bookings_wrong_params
    tests = [
      %w(badparameter), %w(date), %w(limit), %w(status), %w(date limit),
      %w(date limit status), %w(date status), %w(limit status)
    ]
    tests.each do |one|
      get_sth_wrong_params('/resources/1/bookings', one)
    end
  end

  def test_availability_wrong_params
    tests = [%w(badparameter), %w(date), %w(limit), %w(date limit)]
    tests.each do |one|
      get_sth_wrong_params('/resources/1/bookings', one)
    end
  end

  def test_add_bad_booking
    ini_resource
    ini_bookings

    # Fechas erroneas
    post 'resources/asd/bookings', from: '', to: ''
    assert_equal 409, last_response.status

    # Hay otra aprobada del 13 a las 11hs hasta las 12hs.
    post 'resources/1/bookings', from: '2013-11-13T11:00:00Z', to: '2013-11-14T11:00:00Z'
    assert_equal 409, last_response.status
  end

  def test_add_good_booking
    ini_resource

    post 'resources/1/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
  end

  # Con from en medio de otra aceptada.
  def test_add_bk_limit_middle_from
    ini_resource
    ini_bookings

    post 'resources/1/bookings', from: '2013-11-13T11:30:00Z', to: '2013-11-13T13:00:00Z'
    assert_equal 409, last_response.status
  end

  # Con to en medio de otra aceptada.
  def test_add_bk_limit_middle_to
    ini_resource
    ini_bookings

    post 'resources/1/bookings', from: '2013-11-14T10:00:00Z', to: '2013-11-14T11:30:00Z'
    assert_equal 409, last_response.status
  end

  # Justo donde otra termina.
  def test_add_bk_limit_end
    ini_resource
    ini_bookings

    post 'resources/1/bookings', from: '2013-11-13T12:00:00Z', to: '2013-11-13T13:00:00Z'
    assert_equal 201, last_response.status
  end

  # Esta termina donde otra empieza.
  def test_add_bk_limit_begining
    ini_resource
    ini_bookings

    post 'resources/1/bookings', from: '2013-11-14T10:00:00Z', to: '2013-11-14T11:00:00Z'
    assert_equal 201, last_response.status
  end

  def test_add_same_booking
    ini_resource

    post 'resources/1/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
    post 'resources/1/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    assert_equal 201, last_response.status
  end

  def test_accept_one_cancel_the_others
    ini_resource

    post 'resources/1/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    post 'resources/1/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    put "resources/1/bookings/#{bk1.id}"
    bk2 = Booking.last
    assert_equal 'canceled', bk2.status
  end

  def test_accept_nonexistent_booking
    id = 99
    put "resources/1/bookings/#{id}"
    assert_equal 404, last_response.status
  end

  def test_accept_already_accepted_booking
    ini_bookings

    bk1 = Booking.last
    id = bk1.id
    put "resources/1/bookings/#{id}"
    assert_equal 409, last_response.status
  end

  # Trata de aceptar booking de otro recurso
  def test_accept_booking_from_diff_res
    ini_bookings

    put "resources/99/bookings/2"
    assert_equal 409, last_response.status
  end

  def test_accept_pending_booking
    ini_bookings

    put "resources/1/bookings/2"
    assert_equal 200, last_response.status
  end

  def test_accept_canceled_booking
    ini_resource

    post 'resources/1/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    id = bk1.id
    delete "resources/1/bookings/#{id}"
    put "resources/1/bookings/#{id}"
    assert_equal 409, last_response.status
  end

  def test_cancel_booking
    ini_resource

    post 'resources/1/bookings', from: '2013-11-16T11:00:00Z', to: '2013-11-16T12:00:00Z'
    bk1 = Booking.last
    id = bk1.id
    delete "resources/1/bookings/#{id}"
    assert_equal 200, last_response.status
  end

  def test_cancel_nonexistent_booking
    id = 99
    delete "resources/1/bookings/#{id}"
    assert_equal 404, last_response.status
  end
end
