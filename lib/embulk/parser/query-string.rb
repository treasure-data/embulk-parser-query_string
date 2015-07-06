require "uri"

module Embulk
  module Parser

    class QueryString < ParserPlugin
      Plugin.register_parser("query-string", self)

      def self.transaction(config, &control)
        task = {
          strip_quote: config.param("strip_quote", :boolean, default: true),
          strip_whitespace: config.param("strip_whitespace", :boolean, default: true),
        }

        columns = []
        task[:schema] = config.param(:schema, :array, default: [])
        task[:schema].each do |column|
          name = column["name"]
          type = column["type"].to_sym

          columns << Column.new(nil, name, type)
        end

        yield(task, columns)
      end

      def init
        @options = {
          strip_quote: task["strip_quote"],
          strip_whitespace: task["strip_whitespace"],
        }
        @schema = task["schema"]
      end

      def run(file_input)
        while file = file_input.next_file
          file.each do |buffer|
            lines = buffer.lines
            lines.each do |line|
              record = self.class.parse(line, @options)
              records = []
              @schema.each do |column|
                records << record[column["name"]]
              end
              page_builder.add(records)
            end
          end
        end
        page_builder.finish
      end

      def self.parse(line, options = {})
        line.strip! if options[:strip_whitespace]
        if options[:strip_quote]
          line = line[/\A["'](.*?)["']\z/, 1]
        end
        Hash[URI.decode_www_form(line)]
      end
    end

  end
end
