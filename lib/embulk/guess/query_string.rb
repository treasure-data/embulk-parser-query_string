require "embulk/parser/query_string"

module Embulk
  module Guess
    # $ embulk guess -g "query_string" partial-config.yml

    module SchemaGuess
      class << self

        # NOTE: Original #from_hash_records uses keys of the first data only,
        #       but some query key may exist the second line or later.
        # original Embulk::Guess::SchemaGuess is https://github.com/embulk/embulk/blob/57b42c31d1d539177e1e818f294550cde5b69e1f/lib/embulk/guess/schema_guess.rb#L16-L24
        def from_hash_records(array_of_hash)
          array_of_hash = Array(array_of_hash)
          if array_of_hash.empty?
            raise "SchemaGuess Can't guess schema from no records"
          end
          column_names = array_of_hash.map(&:keys).inject([]) {|r, a| r + a }.uniq.sort
          samples = array_of_hash.to_a.map {|hash| column_names.map {|name| hash[name] } }
          from_array_records(column_names, samples)
        end
      end
    end

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
