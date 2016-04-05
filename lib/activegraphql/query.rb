require 'httparty'
require 'active_support/inflector'
require 'activegraphql/support/fancy'

module ActiveGraphql
  class Query < Support::Fancy
    attr_accessor :url, :action, :params, :graph, :response

    class ServerError < StandardError; end

    def get(*graph)
      self.graph = graph

      self.response = HTTParty.get(url, query: { query: to_s })

      fail(ServerError, response_error_messages) if response_errors.present?
      response_data
    end

    def response_data
      return unless response['data']
      to_snake_case(response['data'][qaction])
    end

    def response_errors
      to_snake_case(response['errors'])
    end

    def response_error_messages
      response_errors.map { |e| e[:message] }
    end

    def to_s
      "{ #{qaction}(#{qparams}) { #{qgraph(graph)} } }"
    end

    def qaction
      action.to_s.camelize(:lower)
    end

    def qparams
      params.map do |k, v|
        "#{k.to_s.camelize(:lower)}: \"#{v}\""
      end.join(', ')
    end

    def qgraph(graph)
      graph.map do |item|
        case item
        when Symbol
          item.to_s.camelize(:lower)
        when Hash then
          item.map { |k, v| "#{k.to_s.camelize(:lower)} { #{qgraph(v)} }" }
        end
      end.join(', ')
    end

    private

    def to_snake_case(value)
      case value
      when Array
        value.map { |v| to_snake_case(v) }
      when Hash
        Hash[value.map { |k, v| [k.to_s.underscore.to_sym, to_snake_case(v)] }]
      else
        value
      end
    end
  end
end
