worker_processes 8

working_directory File.expand_path("../../", __FILE__)

listen  "/tmp/aclog-unicorn.sock"

log = "/var/log/rails/unicorn.log"
stderr_path File.expand_path("log/unicorn.log", ENV["RAILS_ROOT"])
stdout_path File.expand_path("log/unicorn.log", ENV["RAILS_ROOT"])

preload_app true

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  old_pid = "#{server.config[:pid]}.old"
  unless old_pid == server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end


