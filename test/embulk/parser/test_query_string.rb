require "prepare_embulk"
require "embulk/parser/query_string"
require "embulk/data_source"

module Embulk
  module Parser
    class QueryStringTest < Test::Unit::TestCase
      class TestParse < self
        def test_without_options
          result = QueryString.parse(line)
          assert_equal(expected, result)
        end

        def test_with_strip_quote
          result = QueryString.parse(quoted_line, strip_quote: true)
          assert_equal(expected, result)
        end

        def test_with_strip_whitespace
          result = QueryString.parse(indented_line, strip_whitespace: true)
          assert_equal(expected, result)
        end

        def test_with_capture
          result = QueryString.parse(indented_line, capture: /^ *(.*)$/)
          assert_equal(expected, result)
        end

        def test_with_capture_and_quote
          result = QueryString.parse(complex_line, strip_quote: true, capture: /^[^"]*(".*?")$/)
          assert_equal(expected, result)
        end

        def test_with_invalid
          mock(Embulk.logger).warn(/#{invalid_line}/) # display whole line if given line is invalid
          result = QueryString.parse(invalid_line)
          assert_nil(result)
        end

        def test_empty_line
          result = QueryString.parse("")
          assert_nil(result)
        end

        def test_empty_matched
          result = QueryString.parse("foo=bar", capture: /foo/) # $1 is undefined, so treated as empty string
          assert_nil(result)
        end

        private

        def expected
          {"foo" => "FOO", "bar" => "3"}
        end

        def line
          %Q(foo=FOO&bar=3)
        end

        def quoted_line
          %Q("#{line}")
        end

        def indented_line
          %Q(  #{line})
        end

        def complex_line
          %Q(Jul 11 11:22:33 ec2-instance-001 : "#{line}")
        end

        def invalid_line
          "invalid=www=form"
        end
      end

      class TestProcessLine < self
        def test_all_keys_exist_in_schema
          mock(page_builder).add(["FOO", 1, Time.parse("2015-07-08T16:25:46")])
          plugin.send(:process_line, line)
        end

        def test_key_nonexist_in_schema
          nonexist_column = Column.new(nil, "different", :long)
          nonexist_schema = schema << nonexist_column

          plugin = QueryString.new(DataSource[task], nonexist_schema, page_builder)
          mock(page_builder).add(["FOO", 1, Time.parse("2015-07-08T16:25:46"), nil])
          plugin.send(:process_line, line)
        end

        def test_long_value_for_key_nonexist
          mock(page_builder).add(["FOO", nil, Time.parse("2015-07-08T16:25:46")])
          plugin.send(:process_line, value_nonexist_line)
        end

        private

        def line
          "foo=FOO&bar=1&baz=2015-07-08T16:25:46"
        end

        def value_nonexist_line
          "foo=FOO&bar=&baz=2015-07-08T16:25:46"
        end
      end

      def test_transaction
        expected_task = task.dup
        expected_task.delete("columns")

        QueryString.transaction(config) do |actual_task, actual_columns|
          assert_equal(expected_task, actual_task)
          assert_equal(schema, actual_columns)
        end
      end

      private

      def plugin
        @plugin ||= QueryString.new(DataSource[task], schema, page_builder)
      end

      def page_builder
        @page_builder ||= Object.new
      end

      def task
        {
          "decoder" => {"Charset" => "UTF-8", "Newline" => "CRLF"},
          "strip_quote" => true,
          "strip_whitespace" => true,
          "capture" => "(.*)",
          "columns" => columns,
        }
      end

      def columns
        [
          {"name" => "foo", "type" => :string},
          {"name" => "bar", "type" => :long},
          {"name" => "baz", "type" => :timestamp},
        ]
      end

      def schema
        columns.map do |column|
          Column.new(nil, column["name"], column["type"].to_sym)
        end
      end

      def config
        DataSource[task.to_a]
      end
    end
  end
end
