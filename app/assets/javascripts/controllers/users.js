Views.users = {
  stats: function() {
    var drawgraph = function(target, data_raw, det) {
        nv.addGraph(function() {
          var size = document.querySelector(target).offsetWidth * 0.6;
          var iconSize = 48;
          var chart = nv.models.pieChart()
            .x(function(d) { return d.screen_name; })
            .y(function(d) { return d.count; })
            .showLabels(true)
            .showLegend(false)
            .donut(true)
            .title("100 tweets / " + data_raw.reactions_count.toString() + " favs")
            .labelsOutside(true);
          var tooltip = chart.tooltip;
          tooltip.contentGenerator(function(d) {
            if (d.data.screen_name) {
              var container, count, iconimg, leftcon, rightcon, screen_name;
              iconimg = document.createElement("img");
              iconimg.setAttribute("src", d.data.profile_image_url);
              leftcon = document.createElement("div");
              leftcon.className = "icon";
              leftcon.appendChild(iconimg);
              screen_name = document.createElement("span");
              screen_name.appendChild(document.createTextNode("@" + d.data.screen_name));
              count = document.createElement("span");
              count.appendChild(document.createTextNode(d.data.count));
              rightcon = document.createElement("div");
              rightcon.className = "meta";
              rightcon.appendChild(screen_name);
              rightcon.appendChild(count);
              container = document.createElement("div");
              container.appendChild(leftcon);
              container.appendChild(rightcon);
              return container.outerHTML;
            } else {
              var container, count, iconimg, rightcon, screen_name;
              screen_name = document.createElement("span");
              screen_name.appendChild(document.createTextNode("Other " + (data_raw.users_count - data_raw.users.length).toString() + " users"));
              count = document.createElement("span");
              count.appendChild(document.createTextNode(d.data.count));
              rightcon = document.createElement("div");
              rightcon.className = "meta";
              rightcon.appendChild(screen_name);
              rightcon.appendChild(count);
              container = document.createElement("div");
              container.appendChild(rightcon);
              return container.outerHTML;
            }
          });
          var svg = d3.select(target + " .chart")
            .attr("height", size)
            .datum(data_raw.users.concat([{ count: (data_raw.reactions_count - data_raw.users.reduce(function(sum, c) { return sum + c.count; }, 0)) }]))
            .transition()
            .call(chart);
          svg.selectAll(".nv-label").each(function(d, i) {
            var group, text;
            group = d3.select(this);
            text = group.select("text").remove();
            return group.append("image").attr("xlink:href", function(d) {
              return d.data.profile_image_url;
            }).attr("width", iconSize).attr("height", iconSize).attr("transform", "translate(-" + iconSize / 2 + ", -" + iconSize / 2 + ")").on("click", function(d) {
              var d = det(d.data);
              return "/" + d[0] + "/favorited_by/" + d[1];
            });
          });
          nv.utils.windowResize(chart.update);
          return chart;
        });
      };

    superagent
      .get("/i/api/users/favorited_by.json")
      .query({ screen_name: Helpers.user_screen_name() })
      .accept("json")
      .end(function(err, res) {
        var json = res.body;
        drawgraph("#favorited_by", res.body, function(user) { return [Helpers.user_screen_name(), user.screen_name]; });
      });
    superagent
      .get("/i/api/users/favorited_users.json")
      .query({ screen_name: Helpers.user_screen_name() })
      .accept("json")
      .end(function(err, res) {
        var json = res.body;
        drawgraph("#favorited_users", res.body, function(user) { return [user.screen_name, Helpers.user_screen_name()]; });
      });
  },
};
