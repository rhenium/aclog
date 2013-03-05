class Receiver::Logger
  include Singleton

  def debug(msg)
    log(@out, "DEBUG", msg)
  end

  def info(msg)
    log(@out, "INFO", msg)
  end

  def warn(msg)
    log(@err, "WARN", msg)
  end

  def error(msg)
    log(@err, "ERROR", msg)
  end

  def log(out, type, msg)
    out.puts Time.now.utc.iso8601(3) + " " + type + ": " + msg
  end

  def initialize
    @out = STDOUT
    @err = STDERR
  end
end
