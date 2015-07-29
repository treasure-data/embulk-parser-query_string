## 0.2.0 - 2015-07-29

This version breaks backword compatibility. With this version, if you use config created by embulk-parser-query_string 0.1.3 or earlier, you should replace `schema:` key name with `columns:` in your config file (e.g. `config.yml`) .

* [fixed] Use "column" as key for schema in config file [#22](https://github.com/treasure-data/embulk-parser-query_string/pull/22) [[reported by @muga](https://github.com/treasure-data/embulk-parser-query_string/issues/21). Thanks!!]
* [enhancement] Display cast error log to human [#19](https://github.com/treasure-data/embulk-parser-query_string/pull/19)
* [maintenace] Fix same name tests weren't run [#18](https://github.com/treasure-data/embulk-parser-query_string/pull/18)

## 0.1.3 - 2015-07-16
* [enhancement] Fix bug nil value casting unexpectedly [#16](https://github.com/treasure-data/embulk-parser-query_string/pull/16)
* [maintenance] Improve test [#15](https://github.com/treasure-data/embulk-parser-query_string/pull/15)

## 0.1.2 - 2015-07-14
* [fixed] Fix to ignore empty line same as invalid line [#14](https://github.com/treasure-data/embulk-parser-query_string/pull/14)

## 0.1.1 - 2015-07-14
* [fixed] Add missing support capture option to parser [#13](https://github.com/treasure-data/embulk-parser-query_string/pull/13)

## 0.1.0 - 2015-07-14
* [enhancement] Add capture option [#11](https://github.com/treasure-data/embulk-parser-query_string/pull/11)

## 0.0.3 - 2015-07-08

* [enhancement] Support embulk 0.6.10 (backward compatibility) [#9](https://github.com/treasure-data/embulk-parser-query_string/pull/9)

## 0.0.2 - 2015-07-08

The name of this plugin is changed to "embulk-parser-query_string" from "embulk-parser-query-string".

* [maintenance] Fix example config in README and sample config [#7](https://github.com/treasure-data/embulk-parser-query_string/pull/7)
* [fixed] Decode line correctly [#6](https://github.com/treasure-data/embulk-parser-query_string/pull/6)
* [fixed] fall back to guess csv [#5](https://github.com/treasure-data/embulk-parser-query_string/pull/5)
* [enhancement] Error handling for parser [#4](https://github.com/treasure-data/embulk-parser-query_string/pull/4)
* [maintenance] Use underscore for plugin name [#3](https://github.com/treasure-data/embulk-parser-query_string/pull/3)

## 0.0.1 - 2015-07-07

The first release!!
