# -*- encoding: utf-8 -*-
require "spec_helper"

describe ApplicationHelper do
  describe "#format_time" do
    let(:str) { "2013-04-14 01:02:03" }
    let(:source) { Time.parse("#{str} +09:00") }
    subject { helper.format_time(source) }
    it { should eq str }
  end

  describe "#format_tweet_text" do
    subject { helper.format_tweet_text(str) }
    context "when contains an @mention" do
      let(:str) { "abcde <mention:cn> eigt" }
      it { should eq "abcde <a href=\"/cn\">@cn</a> eigt" }
    end
    context "when contains an url" do
      let(:str) { "abcde <url:https\\://pbs.twimg.com/media/BL6UraBCIAAyBLH.png\\:large:pbs.twimg.com/media/BL6UraBC…> !!" }
      it { should eq "abcde <a href=\"https://pbs.twimg.com/media/BL6UraBCIAAyBLH.png:large\">pbs.twimg.com/media/BL6UraBC…</a> !!" }
    end
    context "when contains a hashtag" do
      let(:str) { "aidf <hashtag:hashtags> end" }
      it { should eq "aidf <a href=\"https://twitter.com/search?q=%23hashtags\">#hashtags</a> end" }
    end
    context "when contains a symbol" do
      let(:str) { "aidf <symbol:kodaira> end" }
      it { should eq "aidf <a href=\"https://twitter.com/search?q=%24kodaira\">$kodaira</a> end" }
    end
    context "when mixed" do
      let(:str) { "<mention:cn> <symbol:see> this <hashtag:photo> <url:https\\://pbs.twimg.com/media/BL6UraBCIAAyBLH.png\\:large:pbs.twimg.com/media/BL6UraBC…>" }
      it { should eq "<a href=\"/cn\">@cn</a> <a href=\"https://twitter.com/search?q=%24see\">$see</a> this <a href=\"https://twitter.com/search?q=%23photo\">#photo</a> <a href=\"https://pbs.twimg.com/media/BL6UraBCIAAyBLH.png:large\">pbs.twimg.com/media/BL6UraBC…</a>" }
    end
  end
end

