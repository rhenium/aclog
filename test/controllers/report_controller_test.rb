require 'test_helper'

class ReportControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get tweet" do
    get :tweet
    assert_response :success
  end

  test "should get spam" do
    get :spam
    assert_response :success
  end

  test "should get issue" do
    get :issue
    assert_response :success
  end

end
