_rails_root = File.expand_path("../../", __FILE__)

worker_processes 8
working_directory _rails_root

pid File.join(_rails_root, "tmp", "pids", "unicorn.pid").to_s

listen File.join(_rails_root, "tmp", "sockets", "unicorn.sock"), backlog: 64
listen 8080

_log_file = File.join(_rails_root, "log", "unicorn.log")
stderr_path _log_file
stdout_path _log_file

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
    GC.copy_on_write_friendly = true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
