require "spec_helper"

describe ApplicationController do
  describe "#logged_in?" do
    context "when logged in" do
      before do
        session[:account] = FactoryGirl.create(:account_1)
        session[:user_id] = session[:account].user_id
      end
      subject { !!controller.__send__(:logged_in?) }
      it { should be true }
    end

    context "when not logged in" do
      before do
        session[:account] = session[:user_id] = nil
      end
      subject { !!controller.__send__(:logged_in?) }
      it { should be false }
    end
  end

  describe "#authorized_to_show_user?" do
    before do
      @user = FactoryGirl.create(:user, protected: true)
      @account = FactoryGirl.create(:account_1, user: @user)
    end
    let(:user) { @user }
    let(:account) { @account }

    subject { controller.__send__(:authorized_to_show_user?, user) }

    context "when not protected" do
      before { user.protected = false }
      it { should be true }
    end

    context "when protected" do
      context "and logged in" do
        it "as the user" do
          session[:user_id] = user.id
          subject.should be true
        end

        it "as the user's follower" do
          account.stub(:following?).and_return(true)
          session[:account] = account
          subject.should be true
        end

        it "as not the user's follower" do
          account.stub(:following?).and_return(false)
          session[:account] = account
          subject.should be false
        end
      end
    end

    context "when using OAuth Echo" do
      before { request.headers["X-Verify-Credentials-Authorization"] = true }

      it "as the user" do
        controller.stub(:authenticate_with_twitter_oauth_echo).and_return(user.id)
        subject.should be true
      end

      it "as the user's follower" do
        controller.stub(:authenticate_with_twitter_oauth_echo).and_return(user.id)
        user.id += 1
        Account.any_instance.stub(:following?).and_return(true)
        subject.should be true
      end

      it "not as the user's follower" do
        controller.stub(:authenticate_with_twitter_oauth_echo).and_return(user.id + 1)
        Account.any_instance.stub(:following?).and_return(false)
        subject.should be false
      end

      it "but failed in verification" do
        controller.stub(:authenticate_with_twitter_oauth_echo).and_raise(Aclog::Exceptions::OAuthEchoUnauthorized)
        Account.any_instance.stub(:following?).and_return(false)
        subject.should be false
      end
    end
  end

  describe "#authorized_to_show_best?" do
    subject { user; account; !!controller.__send__(:authorized_to_show_best?, user) }

    context "when account is protected" do
      before { controller.stub(:authorized_to_show_user?).and_return(false) }
      let(:user) { FactoryGirl.create(:user, protected: true) }
      let(:account) { FactoryGirl.create(:account_1, user: user) }
      it { should be false }
    end

    context "when account is not protected" do
      before { controller.stub(:authorized_to_show_user?).and_return(true) }
      context "when account is not registered" do
        let(:user) { FactoryGirl.create(:user) }
        let(:account) { nil }
        it { should be false }
      end

      context "when account is private and not logged in as the account" do
        let(:user) { FactoryGirl.create(:user) }
        let(:account) { FactoryGirl.create(:account_1, user: user, private: true) }
        it { should be false }
      end

      context "when account is private and logged in as the account" do
        let(:user) { FactoryGirl.create(:user) }
        let(:account) { FactoryGirl.create(:account_1, user: user, private: true) }
        before do
          session[:user_id] = user.id
          session[:account] = account
        end
        it { should be true }
      end

      context "when account is registered and not private" do
        let(:user) { FactoryGirl.create(:user) }
        let(:account) { FactoryGirl.create(:account_1, user: user) }
        it { should be true }
      end
    end
  end

  describe "#authorize_to_show_user!" do
    subject { -> { controller.__send__(:authorize_to_show_user!, nil) } }
    it "when authorized to show user" do
      controller.stub(:authorized_to_show_user?).and_return(true)
      subject.should_not raise_error
    end

    it "when not authorized to show user" do
      controller.stub(:authorized_to_show_user?).and_return(false)
      subject.should raise_error(Aclog::Exceptions::UserProtected)
    end
  end

  describe "#authorize_to_show_best!" do
    let(:user) { FactoryGirl.create(:user) }
    subject { -> { controller.__send__(:authorize_to_show_best!, user) } }

    context "when user is not protected" do
      before { controller.stub(:authorized_to_show_user?).and_return(true) }

      it "when account is not registered" do
        subject.should raise_error(Aclog::Exceptions::UserNotRegistered)
      end

      it "when account is private and not logged in as the account" do
        FactoryGirl.create(:account_1, user: user, private: true)
        subject.should raise_error(Aclog::Exceptions::AccountPrivate)
      end
    end

    context "when user is protected and not accessible" do
      before { controller.stub(:authorized_to_show_user?).and_return(false) }
      it { should raise_error(Aclog::Exceptions::UserProtected) }
    end

    it "when user is not protected and not private" do
      FactoryGirl.create(:account_1, user: user, private: false)
      subject.should_not raise_error
    end

    it "when user is private but logged in as the user" do
      account = FactoryGirl.create(:account_1, user: user, private: true)
      session[:user_id] = user.id
      session[:account] = account
      subject.should_not raise_error
    end
  end

  # private
  describe "#check_format" do
    subject { -> { controller.__send__(:check_format) } }
    it "when html" do
      request.format = :html
      subject.should_not raise_error
      request.format.should eq :html
    end

    it "when json" do
      request.format = :json
      subject.should_not raise_error
      request.format.should eq :json
    end

    it "when rss" do
      request.format = :rss
      subject.should_not raise_error
      request.format.should eq :rss
    end

    it "when nil" do
      request.format = nil
      controller.params[:format] = nil
      subject.should_not raise_error
      request.format.should eq :html
    end

    it "when else" do
      request.format = :xml
      controller.params[:format] = "xml"
      subject.should raise_error(ActionController::RoutingError)
    end
  end

  describe "#check_session" do
    let(:user) { FactoryGirl.create(:user) }
    let(:account) { FactoryGirl.create(:account_1, user: user) }
    subject { controller.__send__(:check_session) }

    it "when valid session" do
      session[:user_id] = user.id
      session[:account] = account
      subject.should be true
    end

    it "when valid session (not logged in)" do
      session[:user_id] = nil
      session[:account] = nil
      session[:test] = true
      subject.should be true
      session[:test].should be true
    end

    it "when invalid session" do
      session[:user_id] = user.id
      session[:account] = nil
      subject.should be false
      session.key?(:user_id).should be false
    end
  end

  describe "#xhtml" do
    controller do
      def index; render text: nil end
    end

    before do
      get :index
      response.body = "abc\xff\xe3def"
    end

    it "when xhtml" do
      request.format = :html
      controller.__send__(:xhtml)
      response.body.should eq "abc\u{ff}\u{e3}def"
    end

    it "when json" do
      request.format = :json
      controller.__send__(:xhtml)
      response.body.should eq "abc\xff\xe3def"
    end

    it "when rss" do
      request.format = :rss
      controller.__send__(:xhtml)
      response.body.should eq "abc\u{ff}\u{e3}def"
    end
  end
end
