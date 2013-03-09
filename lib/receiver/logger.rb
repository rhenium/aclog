class Receiver::Logger
  def debug(msg)
    if @level == :debug
      log(@out, "DEBUG", msg)
    end
  end

  def info(msg)
    unless @level == :none
           @level == :error
           @level == :warn
      log(@out, "INFO", msg)
    end
  end

  def warn(msg)
    unless @level == :none
           @level == :error
      log(@err, "WARN", msg)
    end
  end

  def error(msg)
    unless @level == :none
      log(@err, "ERROR", msg)
    end
  end

  def fatal(msg)
    log(@err, "FATAL", msg)
  end

  def log(out, type, msg)
    out.puts Time.now.utc.iso8601(3) + " " + type + ": " + msg.to_s
  end

  def initialize(level = :warn)
    @out = STDOUT
    @err = STDERR
    @level = level
  end
end
