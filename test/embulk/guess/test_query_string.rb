require "prepare_embulk"
require "embulk/guess/query_string"
require "embulk/data_source"

module Embulk
  module Guess
    class QueryStringTest < Test::Unit::TestCase
      class TestGuessLines < self
        def test_guess_1
          actual = QueryString.new.guess_lines(config, sample_lines_1)
          expected = {
            "parser" => {
              type: "query_string",
              schema: [
                {name: "foo", type: :long},
                {name: "bar", type: :string},
                {name: "baz", type: :string},
              ]
            }
          }
          assert_equal(expected, actual)
        end

        def test_guess_2
          actual = QueryString.new.guess_lines(config, sample_lines_2)
          expected = {
            "parser" => {
              type: "query_string",
              schema: [
                {name: "foo", type: :long},
                {name: "bar", type: :string},
                {name: "baz", type: :string},
                {name: "hoge", type: :long},
                {name: "xxx", type: :string},
              ]
            }
          }
          assert_equal(expected, actual)
        end

        def test_guess_with_invalid
          actual = QueryString.new.guess_lines(config, sample_lines_with_invalid)
          expected = {
            "parser" => {
              type: "query_string",
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

      def sample_lines_2
        [
          %Q(foo=1&bar=vv&baz=3&hoge=999),
          %Q(foo=2&bar=ss&baz=a&xxx=ABC),
        ]
      end

      def sample_lines_with_invalid
        [
          %Q(foo=1&bar=vv&baz=3),
          %Q(this=line=is=invalid),
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
