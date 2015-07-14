require "capture_io"

module EmbulkRunHelper
  include CaptureIo

  def embulk_guess(seed_path, dest_path)
    silence do
      embulk_exec(%W(guess -g query_string #{seed_path} -o #{dest_path}))
    end
  end

  def embulk_run(yaml_path)
    embulk_exec(%W(run #{yaml_path}))
  end

  def embulk_exec(cli_options = [])
    Embulk.run(cli_options)
  end
end
