require "rails_helper"
require_relative File.expand_path("../../../lib/generators/serviceworker/install_generator", __FILE__)

class ServiceWorker::InstallGeneratorTest < ::Rails::Generators::TestCase
  include GeneratorTestHelpers

  tests Serviceworker::Generators::InstallGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  create_generator_sample_app

  Minitest.after_run do
    remove_generator_sample_app
  end

  setup do
    run_generator
  end

  test "generates serviceworker" do
    assert_file "app/assets/javascripts/serviceworker.js.erb" do |content|
      assert_match(/self.addEventListener\('install', onInstall\)/, content)
    end
  end

  test "generates web app manifest" do
    assert_file "app/assets/javascripts/manifest.json.erb" do |content|
      assert_match(/"name": "My Progressive Rails App"/, content)

      json = JSON.parse(evaluate_erb_asset_template(content))

      assert_equal json["name"], "My Progressive Rails App"
      assert_equal json["icons"].length, ::Rails.configuration.serviceworker.icon_sizes.length
    end
  end

  test "generates companion javascript" do
    assert_file "app/assets/javascripts/serviceworker-companion.js" do |content|
      assert_match(/navigator.serviceWorker.register/, content)
    end

    assert_file "app/assets/javascripts/application.js" do |content|
      assert_match(%r{\n\/\/= require serviceworker-companion}, content)
    end
  end

  test "generates initializer and precompiles assets" do
    assert_file "config/initializers/serviceworker.rb" do |content|
      assert_match(/config.serviceworker.routes.draw/, content)
    end

    assert_file "config/initializers/assets.rb" do |content|
      matcher = /Rails.configuration.assets.precompile \+\= \%w\[serviceworker.js manifest.json\]/
      assert_match(matcher, content)
    end
  end

  test "appends manifest link" do
    assert_file "app/views/layouts/application.html.erb" do |content|
      assert_match(%r{<link rel="manifest" href="/manifest.json" />}, content)
      assert_match(/<meta name="apple-mobile-web-app-capable" content="yes">/, content)
    end
  end

  test "generates offline html" do
    assert_file "public/offline.html"
  end
end
