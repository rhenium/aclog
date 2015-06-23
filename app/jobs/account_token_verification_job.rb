class AccountTokenVerificationJob < ActiveJob::Base
  queue_as :default

  def perform(account_ids)
    Account.where(id: account_ids).each do |account|
      account.verify_token!
    end
  end
end
