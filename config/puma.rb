_rails_root = File.expand_path("../../", __FILE__)

directory _rails_root

_log_file = File.join(_rails_root, "log", "puma.log")
stdout_redirect _log_file, _log_file, true

threads 4, 16
workers 2

bind "unix://" + File.join(_rails_root, "tmp", "sockets", "puma.sock")

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

preload_app!
