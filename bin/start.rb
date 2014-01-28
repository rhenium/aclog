Aclog::Receiver::Worker.spawn!(
  working_dir: Rails.root,
  pid_file: Rails.root.join("tmp", "pids", "receiver.pid").to_s,
  log_file: Rails.root.join("log", "receiver.log").to_s,
  sync_log: true,
  singleton: true
)

