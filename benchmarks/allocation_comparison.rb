require "benchmark/memory"
require 'raven'
require 'raven/breadcrumbs/logger'
require_relative "../spec/support/test_rails_app/app"

TestApp.configure do |config|
  config.middleware.delete ActionDispatch::DebugExceptions
  config.middleware.delete ActionDispatch::ShowExceptions
end

Raven.configure do |config|
  config.logger = Logger.new(nil)
  config.dsn = "dummy://12345:67890@sentry.localdomain:3000/sentry/42"
end

TestApp.initialize!
@app = Rack::MockRequest.new(TestApp)
RAILS_EXC = begin
  @app.get("/exception")
rescue => exc
  exc
end

Raven.capture_exception(RAILS_EXC) # fire it once to get one-time stuff out of rpt

Benchmark.memory do |x|
  x.report("master")  { Raven.capture_exception(RAILS_EXC) }
  x.report("branch") { Raven.capture_exception(RAILS_EXC) }

  x.compare!
  x.hold!("/tmp/allocation_comparison.json")
end

