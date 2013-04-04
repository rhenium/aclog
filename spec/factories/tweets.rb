FactoryGirl.define do
  factory :tweet do |t|
    sequence(:text){|n| "text_" + (n ** 2).to_s}
    sequence(:source){|n| "source_" + (n % 10).to_s}
    sequence(:tweeted_at){|n| Time.at((1199113200..1388502000).to_a.sample)}
  end
end
