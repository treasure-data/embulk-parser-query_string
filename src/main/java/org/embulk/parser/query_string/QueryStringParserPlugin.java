package org.embulk.parser.query_string;

import com.google.common.base.CharMatcher;
import com.google.common.base.Optional;
import com.google.common.base.Strings;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Maps;
import org.embulk.config.Config;
import org.embulk.config.ConfigDefault;
import org.embulk.config.ConfigSource;
import org.embulk.config.Task;
import org.embulk.config.TaskSource;
import org.embulk.spi.Column;
import org.embulk.spi.ColumnVisitor;
import org.embulk.spi.DataException;
import org.embulk.spi.Exec;
import org.embulk.spi.PageBuilder;
import org.embulk.spi.ParserPlugin;
import org.embulk.spi.FileInput;
import org.embulk.spi.PageOutput;
import org.embulk.spi.Schema;
import org.embulk.spi.SchemaConfig;
import org.embulk.spi.json.JsonParseException;
import org.embulk.spi.json.JsonParser;
import org.embulk.spi.time.TimestampParseException;
import org.embulk.spi.time.TimestampParser;
import org.embulk.spi.util.LineDecoder;
import org.embulk.spi.util.Timestamps;
import org.slf4j.Logger;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.LinkedHashMap;
import java.util.Map;

public class QueryStringParserPlugin
        implements ParserPlugin
{
    public interface PluginTask
            extends Task, LineDecoder.DecoderTask, TimestampParser.Task
    {
        @Config("strip_quote")
        @ConfigDefault("true")
        boolean getStripQuote();

        @Config("strip_whitespace")
        @ConfigDefault("true")
        boolean getStripWhitespace();

        @Config("capture")
        @ConfigDefault("null")
        Optional<String> getCapture();

        @Config("stop_on_invalid_record")
        @ConfigDefault("false")
        boolean getStopOnInvalidRecord();

        @Config("columns")
        SchemaConfig getSchemaConfig();
    }

    private final Logger log;

    private String line = null;
    private long lineNumber = 0;

    public QueryStringParserPlugin()
    {
        this.log = Exec.getLogger(this.getClass());
    }

    @Override
    public void transaction(ConfigSource config, ParserPlugin.Control control)
    {
        PluginTask task = config.loadConfig(PluginTask.class);
        Schema schema = task.getSchemaConfig().toSchema();
        control.run(task.dump(), schema);
    }

    @Override
    public void run(TaskSource taskSource, Schema schema,
            FileInput input, PageOutput output)
    {
        PluginTask task = taskSource.loadTask(PluginTask.class);

        final TimestampParser[] timestampParsers = Timestamps.newTimestampColumnParsers(task, task.getSchemaConfig());
        final JsonParser jsonParser = new JsonParser();
        final LineDecoder decoder = newLineDecoder(input, task);
        final boolean stopOnInvalidRecord = task.getStopOnInvalidRecord();

        try (final PageBuilder pageBuilder = new PageBuilder(Exec.getBufferAllocator(), schema, output)) {
            while (decoder.nextFile()) {
                lineNumber = 0;

                while ((line = decoder.poll()) != null) {
                    lineNumber++;

                    try {
                        final Map<String, String> pairs = parseQuery(line, task);

                        if (pairs.isEmpty()) {
                            continue;
                        }

                        schema.visitColumns(new ColumnVisitor()
                        {
                            @Override
                            public void booleanColumn(Column column)
                            {
                                if (trySetNull(column)) {
                                    return;
                                }

                                String v = pairs.get(column.getName());
                                pageBuilder.setBoolean(column, TRUE_STRINGS.contains(v));
                            }

                            @Override
                            public void longColumn(Column column)
                            {
                                if (trySetNull(column)) {
                                    return;
                                }

                                String v = pairs.get(column.getName());
                                try {
                                    pageBuilder.setLong(column, Long.parseLong(v));
                                }
                                catch (NumberFormatException e) {
                                    throw new QueryRecordValidateException(e); // TODO support default value
                                }
                            }

                            @Override
                            public void doubleColumn(Column column)
                            {
                                if (trySetNull(column)) {
                                    return;
                                }

                                String v = pairs.get(column.getName());
                                try {
                                    pageBuilder.setDouble(column, Double.parseDouble(v));
                                }
                                catch (NumberFormatException e) {
                                    throw new QueryRecordValidateException(e); // TODO support default value
                                }
                            }

                            @Override
                            public void stringColumn(Column column)
                            {
                                if (trySetNull(column)) {
                                    return;
                                }

                                String v = pairs.get(column.getName());
                                pageBuilder.setString(column, v);
                            }

                            @Override
                            public void timestampColumn(Column column)
                            {
                                if (trySetNull(column)) {
                                    return;
                                }

                                String v = pairs.get(column.getName());
                                try {
                                    pageBuilder.setTimestamp(column, timestampParsers[column.getIndex()].parse(v));
                                }
                                catch (TimestampParseException e) {
                                    throw new QueryRecordValidateException(e); // TODO support default value
                                }
                            }

                            @Override
                            public void jsonColumn(Column column)
                            {
                                if (trySetNull(column)) {
                                    return;
                                }

                                String v = pairs.get(column.getName());
                                try {
                                    pageBuilder.setJson(column, jsonParser.parse(v));
                                }
                                catch (JsonParseException e) {
                                    throw new QueryRecordValidateException(e); // TODO support default value
                                }
                            }

                            private boolean trySetNull(Column column)
                            {
                                if (!pairs.containsKey(column.getName())) {
                                    pageBuilder.setNull(column);
                                    return true;
                                }

                                String v = pairs.get(column.getName()); // never returns an empty string
                                if (Strings.isNullOrEmpty(v)) {
                                    pageBuilder.setNull(column);
                                    return true;
                                }

                                return false;
                            }
                        });

                        pageBuilder.addRecord();
                    }
                    catch (QueryLineValidateException | QueryRecordValidateException e) {
                        if (stopOnInvalidRecord) {
                            throw new DataException(String.format("Invalid record at line %d: %s", lineNumber, line), e);
                        }

                        log.warn(String.format("Skipped line %d (%s): %s", lineNumber, e.getMessage(), line));
                    }
                }
            }

            pageBuilder.finish();
        }
    }

    // ported from CsvParserPlugin;
    private static final ImmutableSet<String> TRUE_STRINGS =
            ImmutableSet.of(
                    "true", "True", "TRUE",
                    "yes", "Yes", "YES",
                    "t", "T", "y", "Y",
                    "on", "On", "ON",
                    "1");

    public static Map<String, String> parseQuery(String queryLine, PluginTask task)
            throws QueryLineValidateException
    {
        if (Strings.isNullOrEmpty(queryLine)) {
            return Maps.newHashMap();
        }

        String line;

        // capture TODO

        // strip whitespace
        line = task.getStripWhitespace() ? CharMatcher.WHITESPACE.trimFrom(queryLine) : queryLine;

        // strip quote
        line = task.getStripQuote() ? CharMatcher.is('\"').is('\'').trimFrom(line) : line;

        Map<String, String> pairs = Maps.newHashMap();
        String[] split = line.split("&");

        try {
            for (String pair : split) {
                int i = pair.indexOf("=");
                String key = i > 0 ? URLDecoder.decode(pair.substring(0, i), "UTF-8") : pair;
                String value = i > 0 && pair.length() > i + 1 ? URLDecoder.decode(pair.substring(i + 1), "UTF-8") : null;
                pairs.put(key, value);
            }

            return pairs;
        }
        catch (UnsupportedEncodingException e) {
            throw new QueryLineValidateException(e);
        }
    }

    public static LineDecoder newLineDecoder(FileInput input, PluginTask task)
    {
        return new LineDecoder(input, task);
    }

    static class QueryLineValidateException
            extends DataException
    {
        QueryLineValidateException(Throwable cause)
        {
            super(cause);
        }
    }

    static class QueryRecordValidateException
            extends DataException
    {
        QueryRecordValidateException(Throwable cause)
        {
            super(cause);
        }
    }
}
