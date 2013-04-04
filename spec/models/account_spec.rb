# -*- coding: utf-8 -*-
require 'spec_helper'

describe Account do
  describe "Account.register_or_update" do
    it "登録されていなかった時 新しいレコードを作る。" do
      account_1 = FactoryGirl.build(:account_1)
      created_1 = Account.register_or_update(user_id: account_1.user_id,
                                             oauth_token: account_1.oauth_token,
                                             oauth_token_secret: account_1.oauth_token_secret,
                                             consumer_version: account_1.consumer_version)
      created_1.user_id.should eq account_1.user_id
    end

    it "登録されていた時 レコードを更新する。" do
      created_1 = FactoryGirl.create(:account_1)

      account_2 = FactoryGirl.build(:account_2)
      created_2 = Account.register_or_update(user_id: account_2.user_id,
                                             oauth_token: account_2.oauth_token,
                                             oauth_token_secret: account_2.oauth_token_secret,
                                             consumer_version: account_2.consumer_version)
      created_2.oauth_token.should eq account_2.oauth_token
      created_2.id.should eq created_1.id
    end
  end

  describe "Account#user" do
    before(:each){@account_1 = FactoryGirl.create(:account_1)}

    it "ユーザーが記録されていた時 User を返す。" do
      FactoryGirl.create(:user_1)

      got_user = @account_1.user
      got_user.id.should eq @account_1.user_id
    end

    it "ユーザーが記録されていなかった時 nil を返す。" do
      got_user = @account_1.user
      got_user.should eq nil
    end
  end

  describe "Account#twitter_user" do
    before(:each){@account_1 = FactoryGirl.create(:account_1)}

    it "ユーザーが存在する時 Twitter::User を返す。" do
      user = FactoryGirl.create(:user_exists)

      got_user = @account_1.twitter_user(user.id)
      got_user.screen_name.should eq user.screen_name
    end

    it "ユーザーが存在しない時 nil を返す。" do
      user = FactoryGirl.create(:user_not_exists)

      got_user = @account_1.twitter_user(user.id)
      got_user.should eq nil
    end

    it "ユーザーが凍結している時 nil を返す。" do
      user = FactoryGirl.create(:user_suspended)

      got_user = @account_1.twitter_user(user.id)
      got_user.should eq nil
    end

    it "引数を省略した時自分の user_id を使う。" do
      user = FactoryGirl.create(:user_1)

      got_user = @account_1.twitter_user
      got_user.screen_name.should eq user.screen_name
    end
  end

  describe "Account.import_favorites" do
  end
end
