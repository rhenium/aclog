class Issue < ActiveRecord::Base
  def self.register(issue_type, status, data)
    create!(issue_type: issue_type, status: status, data: Yajl::Encoder::encode(data))
  end
end
