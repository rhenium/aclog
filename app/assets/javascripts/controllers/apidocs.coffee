Views.apidocs =
  endpoint: ->
    loading = $("#example_request_loading")
    if loading isnt null
      code = loading.parent()
      superagent
        .get $("#example_request_uri").text()
        .accept "json"
        .end (err, res) ->
          if res.ok
            code.text(JSON.stringify(res.body, null, 2))
          else
            code.text("failed to load example....")
