require "embulk/parser/query_string"

module Embulk
  module Guess
    # $ embulk guess -g "query_string" partial-config.yml

    class QueryString < LineGuessPlugin
      Plugin.register_guess("query_string", self)

      def guess_lines(config, sample_lines)
        return {} unless config.fetch("parser", {}).fetch("type", "query_string") == "query_string"

        parser_config = config.param("parser", :hash)
        options = {
          strip_quote: parser_config.param("strip_quote", :bool, default: true),
          strip_whitespace: parser_config.param("strip_whitespace", :bool, default: true),
          capture: parser_config.param("capture", :string, default: nil)
        }
        records = sample_lines.map do |line|
          Parser::QueryString.parse(line, options) || {}
        end

        columns = Guess::SchemaGuess.from_hash_records(records)
        columns = columns.map do |c|
          column = {name: c.name, type: c.type}
          column[:format] = c.format if c.format
          column
        end

        guessed = {
          type: "query_string",
          columns: columns
        }

        return {"parser" => guessed}
      end
    end

  end
end
