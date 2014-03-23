namespace :web do
  @pid_file = Rails.root.join("tmp", "pids", "puma.pid").to_s
  
  def read_pid
    Integer(File.read(@pid_file)) rescue nil
  end
  
  def process_alive?(pid)
    Process.kill(0, pid) rescue false
  end

  desc "Start web server (puma)"
  task :start do
    pid = read_pid
    if pid && process_alive?(pid)
      STDERR.puts "Puma is already started (PID: #{pid})"
      next
    end
    echo `puma -d -e #{Rails.env} -C #{Rails.root}/config/puma.rb --pidfile #{@pid_file}`
  end

  desc "Stop web server (puma)"
  task :stop do
    pid = read_pid
    unless process_alive?(pid)
      STDERR.puts "Puma is not running."
      next
    end

    Process.kill("TERM", pid)
    while process_alive?(pid)
      sleep 0.1
    end
  end

  desc "Retart web server (puma)"
  task :restart do
    pid = read_pid
    unless process_alive?(pid)
      STDERR.puts "Puma is not running."
      Rake::Task["web:start"].invoke
    end

    Process.kill("USR2", pid)
  end

  desc "Show status of web server (puma)"
  task :status do
    pid = read_pid
    if pid && process_alive?(pid)
      STDOUT.puts "Puma is running."
    else
      STDOUT.puts "Puma is not running."
    end
  end
end
