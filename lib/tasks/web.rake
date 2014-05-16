namespace :web do
  @web_pid_file = Rails.root.join("tmp", "pids", "unicorn.pid").to_s
  
  def web_read_pid
    Integer(File.read(@web_pid_file)) rescue nil
  end
  
  def process_alive?(pid)
    Process.kill(0, pid) rescue false
  end

  desc "Start web server (Unicorn)"
  task :start do
    pid = web_read_pid
    if pid && process_alive?(pid)
      STDERR.puts "Unicorn is already started (PID: #{pid})"
      next
    end
    puts `unicorn -D -E #{Rails.env} -c #{Rails.root}/config/unicorn.rb`
  end

  desc "Stop web server (Unicorn)"
  task :stop do
    pid = web_read_pid
    unless process_alive?(pid)
      STDERR.puts "Unicorn is not running."
      next
    end

    Process.kill(:QUIT, pid)
    while process_alive?(pid)
      sleep 0.1
    end
  end

  desc "Retart web server (Unicorn)"
  task :restart do
    pid = web_read_pid
    unless process_alive?(pid)
      STDERR.puts "Unicorn is not running."
      Rake::Task["web:start"].invoke
    end

    Process.kill("USR2", pid)
  end

  desc "Show status of web server (Unicorn)"
  task :status do
    pid = web_read_pid
    if pid && process_alive?(pid)
      STDOUT.puts "Unicorn is running."
    else
      STDOUT.puts "Unicorn is not running."
    end
  end
end
