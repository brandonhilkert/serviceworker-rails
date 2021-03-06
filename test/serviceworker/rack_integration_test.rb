require "rails_helper"

class ServiceWorker::RackIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def handler
    ServiceWorker::Handler.new(Pathname.new(Dir.pwd).join("test/static"))
  end

  def router
    ServiceWorker::Router.new do
      match "/serviceworker.js" => "assets/serviceworker.js"
    end
  end

  def app
    config = {
      routes: router,
      handler: handler
    }
    Rack::Builder.new do
      map "/" do
        use ServiceWorker::Middleware, config
        run ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
      end
    end
  end

  def test_serviceworker_route
    get "/serviceworker.js"

    assert last_response.ok?, "Expected a 200 response but got a #{last_response.status}"
    assert_equal "application/javascript", last_response.headers["Content-Type"]
    assert_equal "private, max-age=0, no-cache", last_response.headers["Cache-Control"]
    assert_match(/console.log\(.*'Hello from Rack ServiceWorker!'.*\);/, last_response.body)
  end
end
