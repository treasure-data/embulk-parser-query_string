require "prepare_embulk"
require "embulk/parser/query-string"
require "embulk/data_source"

module Embulk
  module Parser
    class QueryStringPluginTest < Test::Unit::TestCase
      class TestParse < self
        def test_parse_line_without_options
          result = QueryString.parse(line)
          assert_equal(expected, result)
        end

        def test_parse_line_with_strip_quote
          result = QueryString.parse(quoted_line, strip_quote: true)
          assert_equal(expected, result)
        end

        def test_parse_line_with_strip_whitespace
          result = QueryString.parse(indented_line, strip_whitespace: true)
          assert_equal(expected, result)
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
      end

      class TestProcessBuffer < self
        setup :setup_plugin

        def test_process_buffer
          records.each do |record|
            mock(page_builder).add(record.values)
          end
          @plugin.send(:process_buffer, buffer)
        end

        private

        def records
          [
            {"foo" => "FOO", "bar" => "1"},
            {"foo" => "Foo", "bar" => "2"},
          ]
        end

        def buffer
          "foo=FOO&bar=1\nfoo=Foo&bar=2"
        end
      end

      def test_transaction
        QueryString.transaction(config) do |actual_task, actual_columns|
          t = task.dup
          t.delete(:schema)
          assert_equal(t, actual_task)
          assert_equal(schema, actual_columns)
        end
      end

      private

      def setup_plugin
        plugin
      end

      def plugin
        @plugin ||= QueryString.new(task, schema, page_builder)
      end

      def page_builder
        @page_builder ||= Object.new
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