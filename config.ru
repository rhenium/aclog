require ::File.expand_path('../config/environment',  __FILE__)

if Rails.env.production?
  # Unicorn self-process killer
  require 'unicorn/worker_killer'
  
  # Max requests per worker
  use Unicorn::WorkerKiller::MaxRequests, 3072, 4096
  
  # Max memory size (RSS) per worker
  use Unicorn::WorkerKiller::Oom, (144*(1024**2)), (256*(1024**2))
end

run Aclog::Application

