# frozen_string_literal: true

module ElasticAPM
  # @api private
  class Middleware
    def initialize(app)
      @app = app
    end

    # rubocop:disable Metrics/MethodLength
    def call(env)
      begin
        transaction = ElasticAPM.transaction 'Rack', 'app',
          context: ElasticAPM.build_context(env)

        resp = @app.call env
        status, headers, = resp

        if transaction
          transaction.submit(status, status: status, headers: headers)
        end
      rescue InternalError
        raise # Don't report ElasticAPM errors
      rescue ::Exception => e
        ElasticAPM.report(e, handled: false)
        transaction.submit(500, status: 500) if transaction
        raise
      ensure
        transaction.release if transaction
      end

      resp
    end
    # rubocop:enable Metrics/MethodLength
  end
end
