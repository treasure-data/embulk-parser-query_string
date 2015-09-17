require "yaml"
require "tmpdir"
require "prepare_embulk"
require "embulk_run_helper"

module Embulk
  class EmbulkRunTest < Test::Unit::TestCase
    include EmbulkRunHelper

    def setup
      @dir = Dir.mktmpdir
      @target_file = "#{@dir}/target_file.txt"
      File.open(@target_file, "w") do |f|
        f.write <<-FILE
          "foo=FOO&bar=1"
          "foo=FOO&bar=2"
          "foo=FOO&bar=3"
          "foo=FOO&bar=4"
          "foo=FOO&bar=5"
          "foo=FOO&bar=6"
          "foo=FOO&bar=7"
          "foo=FOO&bar=8"
          "foo=FOO&bar=9"
          "foo=FOO&bar=10"
          "foo=FOO&bar=11"
          "foo=FOO&bar=12"
          "foo=FOO&bar=13"
        FILE
      end
    end

    def teardown
      FileUtils.rm_rf @dir
    end

    def test_embulk_run
      config_path = "#{@dir}/config.yml"
      File.open(config_path, "w") do |f|
        f.write guessed_content
      end
      out = capture do
        embulk_run(config_path)
      end

      assert_true(out.include?(<<-CONTENT))
1,FOO
2,FOO
3,FOO
4,FOO
5,FOO
6,FOO
7,FOO
8,FOO
9,FOO
10,FOO
11,FOO
12,FOO
13,FOO
      CONTENT
    end

    def test_embulk_guess
      seed_path = "#{@dir}/seed.yml"
      File.open(seed_path, "w") do |f|
        f.write seed_content
      end
      dest_path = "#{@dir}/guessed.yml"
      embulk_guess(seed_path, dest_path)
      guessed = IO.read(dest_path)

      assert_equal(guessed_content, guessed)
    end

    private

    def seed_content
      <<YAML
in:
  type: file
  path_prefix: #{@dir}/target_file
  parser:
    strip_quote: true
    strip_whitespace: true
exec: {}
out: {type: stdout}
YAML
    end

    def guessed_content
      <<YAML
in:
  type: file
  path_prefix: #{@dir}/target_file
  parser:
    strip_quote: true
    strip_whitespace: true
    charset: UTF-8
    newline: CRLF
    type: query_string
    columns:
    - {name: bar, type: long}
    - {name: foo, type: string}
exec: {}
out: {type: stdout}
YAML
    end
  end
end

