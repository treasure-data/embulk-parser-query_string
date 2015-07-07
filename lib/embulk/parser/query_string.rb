require "uri"

module Embulk
  module Parser

    class QueryString < ParserPlugin
      Plugin.register_parser("query_string", self)

      def self.transaction(config, &control)
        task = {
          strip_quote: config.param("strip_quote", :bool, default: true),
          strip_whitespace: config.param("strip_whitespace", :bool, default: true),
        }

        columns = []
        schema = config.param(:schema, :array, default: [])
        schema.each do |column|
          name = column["name"]
          type = column["type"].to_sym

          columns << Column.new(nil, name, type)
        end

        yield(task, columns)
      end

      def init
        @options = {
          strip_quote: task[:strip_quote],
          strip_whitespace: task[:strip_whitespace],
        }
      end

      def run(file_input)
        while file = file_input.next_file
          file.each do |buffer|
            process_buffer(buffer)
          end
        end
        page_builder.finish
      end

      def self.parse(line, options = {})
        line.chomp!
        line.strip! if options[:strip_whitespace]
        if options[:strip_quote]
          line = line[/\A(?:["'])?(.*?)(?:["'])?\z/, 1]
        end

        begin
          Hash[URI.decode_www_form(line)]
        rescue ArgumentError
          nil
        end
      end

      private

      def process_buffer(buffer)
        lines = buffer.lines
        lines.each do |line|
          record = self.class.parse(line, @options)

          next unless record

          records = schema.map do |column|
            record[column.name]
          end
          page_builder.add(records)
        end
      end
    end

  end
end