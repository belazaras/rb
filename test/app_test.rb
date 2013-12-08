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
    get '/resources/999'
    assert_equal 404, last_response.status
    assert_equal 'Not Found', last_response.body
  end
end
