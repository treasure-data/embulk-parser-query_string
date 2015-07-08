require "embulk/command/embulk_run"

classpath_dir = Embulk.home("classpath")
jars = Dir.entries(classpath_dir).select{|f| f =~ /\.jar$/ }.sort
jars.each do |jar|
  require File.join(classpath_dir, jar)
end

props = java.util.Properties.new
props.setProperty("embulk.use_global_ruby_runtime", "true")

bootstrap_model_manager = org.embulk.config.ModelManager.new(nil, com.fasterxml.jackson.databind.ObjectMapper.new)
system_config = org.embulk.config.ConfigLoader.new(bootstrap_model_manager).fromPropertiesYamlLiteral(props, "embulk.")
org.embulk.EmbulkService.new(system_config).injector.getInstance(java.lang.Class.forName('org.jruby.embed.ScriptingContainer'))

require "embulk"
