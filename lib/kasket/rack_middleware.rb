module Kasket
  class RackMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      Kasket.cache.enable_local = true
      @app.call(env)
    ensure
      Kasket.cache.enable_local = false
    end
  end
end
