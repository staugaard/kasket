module Kasket
  class RackMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    ensure
      Kasket.cache.clear_local
    end
  end
end
