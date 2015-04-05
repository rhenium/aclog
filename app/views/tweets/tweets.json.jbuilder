if @tweets.length > 0
  if !params[:page] && @tweets.order_values.all? {|o| !o.is_a?(String) && o.expr.name == :id }
    json.prev url_for(params.tap {|h| h.delete(:max_id) }.merge(since_id: @tweets.first.id))
    json.next url_for(params.tap {|h| h.delete(:since_id) }.merge(max_id: @tweets.last.id - 1))
  else
    page = [params[:page].to_i, 1].max
    json.prev page == 1 ? nil : url_for(params.merge(page: page - 1))
    json.next url_for(params.merge(page: page + 1))
  end
else
  json.prev nil
  json.next nil
end

json.statuses @tweets, partial: "tweet", as: :tweet
