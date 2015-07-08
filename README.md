[![Build Status](https://travis-ci.org/treasure-data/embulk-parser-query_string.svg)](https://travis-ci.org/treasure-data/embulk-parser-query_string)
[![Code Climate](https://codeclimate.com/github/treasure-data/embulk-parser-query_string/badges/gpa.svg)](https://codeclimate.com/github/treasure-data/embulk-parser-query_string)
[![Test Coverage](https://codeclimate.com/github/treasure-data/embulk-parser-query_string/badges/coverage.svg)](https://codeclimate.com/github/treasure-data/embulk-parser-query_string/coverage)

# Query String parser plugin for [Embulk](http://www.embulk.org)

Transform `key=value&key2=value2` line to `{key: "value", key2: "value2"}`. (HTTP Query String to Hash)

Currently, this plugin supports minimum case, some edge cases are unsupported as below.

- Duplicated key (e.g. `key=1&key=2`)
- Array parameter (e.g. `key[]=1&key[]=2`)

## Overview

* **Plugin type**: parser
* **Guess supported**: yes

## Configuration

- **strip_quote**: If you have quoted lines file such as `"foo=FOO&bar=BAR"`, should be true for strip their quotes. (bool, default: true)
- **strip_whitespace**: Strip whitespace before parsing lines for any indented line parse correctly such as '  foo=FOO'. (bool, default: true)

## Example

You have such text file (`target_file.txt`) as below:

```text
"user_id=42&some_param=ABC"
"user_id=43&some_param=EFG"
"user_id=44&some_param=XYZ"
```

And you have `partial-config.yml` as below:

```yaml
in:
  type: file
  path_prefix: ./target_file
  parser:
    strip_quote: true
    strip_whitespace: true
exec: {}
out: {type: stdout}
```

Run `embulk guess`.

```
$ embulk guess -g query_string partial-config.yml -o guessed.yml
```

You got guessed.yml as below:

```yaml
in:
  type: file
  path_prefix: ./target_file
  parser:
    strip_quote: true
    strip_whitespace: true
    charset: ISO-8859-2
    newline: CRLF
    type: query_string
    schema:
    - {name: user_id, type: long}
    - {name: some_param, type: string}
exec: {}
out: {type: stdout}
```

Finally, `embulk run` with generated guessed.yml.

```
$ embulk run guessed.yml
```

You can see the parsed records on STDOUT.

## Install plugin

```
$ embulk gem install embulk-parser-query_string
```
