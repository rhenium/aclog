Dir.glob(File.expand_path("../apidoc/**/*.rb", __FILE__)) {|file| require file }

module Apidoc
  extend self

  def resources
    @@resources ||= {}
  end

  def reload_docs
  end
end
