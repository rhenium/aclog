namespace :collector do
  @collector_pid_file = Rails.root.join("tmp", "pids", "collector.pid").to_s
  @collector_log_file = Rails.root.join("log", "collector.log").to_s
  
  def collector_read_pid
    Integer(File.read(@collector_pid_file)) rescue nil
  end
  
  def process_alive?(pid)
    Process.kill(0, pid) rescue false
  end

  desc "Start aclog collector (master) in the foreground"
  task run: :environment do
    require Rails.root.join("collector/daemon")
    Collector::Daemon.start
  end
  
  desc "Start aclog collector (master)"
  task start: :environment do
    require Rails.root.join("collector/daemon")
    pid = collector_read_pid
    if pid && process_alive?(pid)
      STDERR.puts "Collector daemon is already started (PID: #{pid})"
      next
    end

    Process.daemon
    File.open(@collector_pid_file, "w").write(Process.pid)

    log = File.open(@collector_log_file, "a")
    log.sync = true
    STDOUT.reopen(log)
    STDERR.reopen(STDOUT)

    Collector::Daemon.start
  end

  desc "Stop aclog collector (master)"
  task :stop do
    pid = collector_read_pid
    unless process_alive?(pid)
      puts "Collector daemon is not started."
      next
    end

    Process.kill("TERM", pid)
    while process_alive?(pid)
      sleep 0.1
    end

    File.delete(@collector_pid_file)
  end

  desc "Retart aclog collector (master)"
  task :restart do
    Rake::Task["collector:stop"].invoke
    Rake::Task["collector:start"].invoke
  end

  desc "Show status of running aclog collector (master)"
  task :status do
    pid = collector_read_pid
    if pid && process_alive?(pid)
      puts "Collector is running."
    else
      puts "Collector is not running."
    end
  end
end
