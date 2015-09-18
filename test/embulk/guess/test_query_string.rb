require "prepare_embulk"
require "embulk/guess/query_string"
require "embulk/data_source"

module Embulk
  module Guess
    class QueryStringTest < Test::Unit::TestCase
      class TestGuessLines < self
        data do
          {
            same_keys: [sample_lines_with_same_keys, columns_with_same_keys],
            different_keys: [sample_lines_with_different_keys, columns_with_different_keys],
            invalid: [sample_lines_with_invalid, columns_with_invalid],

          }
        end

        def test_columns(data)
          stub(Embulk.logger).warn {}

          sample_lines, columns = data
          actual = QueryString.new.guess_lines(config, sample_lines)
          expected = {
            "parser" => {
              type: "query_string",
              columns: columns
            }
          }
          assert_equal(expected, actual)
        end

        def test_warn_invalid_columns
          mock(Embulk.logger).warn(/Failed parse/)

          QueryString.new.guess_lines(config, self.class.sample_lines_with_invalid)
        end

        data do
          valid_columns = {
            "parser" => {
              type: "query_string",
              columns: columns_with_same_keys,
            }
          }

          {
            "query_string" => ["query_string", valid_columns],
            "other" => ["other", {}],
          }
        end

        def test_type(data)
          type, expected = data
          sample_lines = self.class.sample_lines_with_same_keys
          config = DataSource[{"parser" => {"type" => type}}]

          actual = QueryString.new.guess_lines(config, sample_lines)
          assert_equal(expected, actual)
        end
      end

      private

      class << self
        def sample_lines_with_same_keys
          [
            %Q(foo=1&bar=vv&baz=3&time=2015-07-08T16%3A25%3A46%2B09%3A00),
            %Q(foo=2&bar=ss&baz=a&time=2015-07-09T16%3A25%3A46),
          ]
        end

        def columns_with_same_keys
          [
            {name: "bar", type: :string},
            {name: "baz", type: :string},
            {name: "foo", type: :long},
            {name: "time", type: :timestamp, format: "%Y-%m-%dT%H:%M:%S"}
          ]
        end

        def sample_lines_with_different_keys
          [
            %Q(foo=1&bar=vv&baz=3&hoge=999),
            %Q(foo=2&bar=ss&baz=a&xxx=ABC),
          ]
        end

        def columns_with_different_keys
          [
            {name: "bar", type: :string},
            {name: "baz", type: :string},
            {name: "foo", type: :long},
            {name: "hoge", type: :long},
            {name: "xxx", type: :string},
          ]
        end

        def sample_lines_with_invalid
          [
            %Q(foo=1&bar=vv&baz=3),
            %Q(this=line=is=invalid),
            %Q(foo=2&bar=ss&baz=a),
          ]
        end

        def columns_with_invalid
          [
            {name: "bar", type: :string},
            {name: "baz", type: :string},
            {name: "foo", type: :long},
          ]
        end
      end

      def task
        {
          "parser" => {
            "strip_quote" => true,
            "strip_whitespace" => true,
            "columns" => columns,
          }
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
