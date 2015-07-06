require "prepare_embulk"
require "embulk/guess/query-string"
require "embulk/data_source"

module Embulk
  module Guess
    class QueryStringPluginTest < Test::Unit::TestCase
      class TestGuessLines < self
        def test_parse_line_without_options
          actual = QueryString.new.guess_lines(config, sample_lines_1)
          expected = {
            "parser" => {
              type: "query-string",
              schema: [
                {name: "foo", type: :long},
                {name: "bar", type: :string},
                {name: "baz", type: :string},
              ]
            }
          }
          assert_equal(expected, actual)
        end
      end

      private

      def sample_lines_1
        [
          %Q(foo=1&bar=vv&baz=3),
          %Q(foo=2&bar=ss&baz=a),
        ]
      end

      def task
        {
          strip_quote: true,
          strip_whitespace: true,
          schema: columns,
        }
      end

      def columns
        [
          {"name" => "foo", "type" => "string"},
          {"name" => "bar", "type" => "string"},
        ]
      end

      def config
        DataSource[task.to_a]
      end
    end
  end
end
