require "embulk/parser/query_string"

module Embulk
  module Guess
    # $ embulk guess -g "query_string" partial-config.yml

    class QueryString < LineGuessPlugin
      Plugin.register_guess("query_string", self)

      def guess_lines(config, sample_lines)
        options = {
          strip_quote: config.param("strip_quote", :bool, default: true),
          strip_whitespace: config.param("strip_whitespace", :bool, default: true)
        }
        records = sample_lines.map do |line|
          Parser::QueryString.parse(line, options) || {}
        end
        format = records.inject({}) do |result, record|
          record.each_pair do |key, value|
            (result[key] ||= []) << value
          end
          result
        end
        guessed = {type: "query_string", schema: []}
        format.each_pair do |key, values|
          if values.any? {|value| value.match(/[^0-9]/) }
            guessed[:schema] << {name: key, type: :string}
          else
            guessed[:schema] << {name: key, type: :long}
          end
        end
        return {"parser" => guessed}
      end
    end

  end
end
