json.array! @items do |json, item|
  json.partial! "shared/tweet", :item => item
end

