require "spec_helper"

describe ApplicationHelper do
  describe "#format_tweet_text" do
    subject { helper.format_tweet_text(str) }
    context "when contains an @mention" do
      let(:str) { "abcde @cn eigt" }
      it { should match /abcde <a .*?href=\"\/cn\".*?>@cn<\/a> eigt/ }
    end
    context "when contains an url" do
      let(:str) { "abcde https://pbs.twimg.com/media/BL6UraBCIAAyBLH.png:large !!" }
      it { should match /abcde <a .*?href=\"https:\/\/pbs\.twimg\.com\/media\/BL6UraBCIAAyBLH\.png:large\".*?>.*?<\/a> !!/ }
    end
    context "when contains a hashtag" do
      let(:str) { "aidf #hashtags end" }
      it { should match /aidf <a .*?href=\"https:\/\/twitter\.com\/(#!\/)?search\?q=%23hashtags\".*?>#hashtags<\/a> end/ }
    end
    context "when contains a symbol" do
      let(:str) { "aidf $kodair end" }
      it { should match /aidf <a .*?href=\"https:\/\/twitter\.com\/(#!\/)?search\?q=%24kodair\".*?>\$kodair<\/a> end/ }
    end
    context "when mixed" do
      let(:str) { "@cn $see this #photo https://pbs.twimg.com/media/BL6UraBCIAAyBLH.png:large" }
      it { should match /<a .*?href=\"\/cn\".*?>@cn<\/a> <a .*?href=\"https:\/\/twitter\.com\/(#!\/)?search\?q=%24see\".*?>\$see<\/a> this <a .*?href=\"https:\/\/twitter\.com\/(#!\/)?search\?q=%23photo\".*?>#photo<\/a> <a .*?href=\"https:\/\/pbs\.twimg\.com\/media\/BL6UraBCIAAyBLH\.png:large\".*?>.*?<\/a>/ }
    end
  end
end

