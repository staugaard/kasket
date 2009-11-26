module CacheBack
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      result = @app.call(env)
      CacheBack.cache.reset!
      result
    end
  end
end