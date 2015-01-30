Application.Views.apidocs =
    endpoint: ->
        loading = $("#example_request_loading")
        if loading isnt null
            code = loading.parent()
            $.ajax($("#example_request_uri").text()).done((data) ->
              code.text(JSON.stringify(data, null, 2))
            ).fail(->
              code.text("failed to load example....")
            )
