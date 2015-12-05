<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3 col-md-offset-1">
        <sidebar v-bind:user="user"></sidebar>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <div class="favorite-graph">
          <div v-for="one in data">
            <h2>{{one.title}}</h2>
            <div class="loading-box" v-if="one.loading">
              <img class="loading-image" src="/assets/loading.gif" />
            </div>
            <template v-else>
              <div class="chart">
                <div class="chart-item other" v-if="one.users_count &gt; one.users.length" v-bind:style="{ 'background-color': itemColor(one.users.length) }">
                  <span>Other {{ one.users_count - one.users.length }} People</span>
                </div>
                <div class="chart-item" v-on:click="openTweets(user, one)" v-for="user in one.users" v-bind:style="{ 'width': (100 * user.count / one.reactions_count) + '%', 'background-color': itemColor(one.users.length - $index - 1) }">
                  <div class="popout">
                    <img alt="@{{user.screen_name}}" class="twitter-icon" v-bind:src="user.profile_image_url" v-on:error="failProfileImage" />
                    <div class="count">
                      <span>{{user.count}}</span>
                      favs
                    </div>
                  </div>
                </div>
              </div>
              <div class="statuses" v-if="one.showTweets">
                <tweet v-for="tweet in one.tweets" v-bind:tweet="tweet"></tweet>
                <div class="loading-box" v-if="one.loadingTweets">
                  <img class="loading-image" src="/assets/loading.gif" />
                </div>
                <div class="refresh-box" v-else><a v-link="currentPermalink(one)">&#187;</a></div>
              </div>
            </template>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";

const itemColors = ["#393b79", "#5254a3", "#6b6ecf", "#9c9ede", "#637939", "#8ca252", "#b5cf6b", "#cedb9c", "#8c6d31", "#bd9e39", "#e7ba52", "#e7cb94", "#843c39", "#ad494a", "#d6616b", "#e7969c", "#7b4173", "#a55194", "#ce6dbd", "#de9ed6"];

export default {
  data: function() {
    return {
      data: [
      {
        title: "Favorited by..",
        loading: true,
        tweets: [],
        showTweets: false,
        loadingTweets: false
      },
      {
        title: "Favoriting..",
        loading: true,
        tweets: [],
        showTweets: false,
        loadingTweets: false
      }
      ],
      user: null,
    };
  },
  methods: {
    itemColor: function(i) {
      return itemColors[i % itemColors.length];
    },
    currentPermalink: function(one) {
      var sn = one.lastUser.screen_name;
      return one._permalink.replace(/:screen_name/, sn);
    },
    openTweets: function(user, one, e) {
      if (!one.showTweets || user === one.lastUser) {
        one.showTweets = !one.showTweets;
      }
      if (one.showTweets) {
        one.lastUser = user;
        one.loadingTweets = true;
        var params = {};
        Object.keys(one._tweets).forEach(key => {
          if (one._tweets[key] === ":screen_name") {
            params[key] = user.screen_name
          } else {
            params[key] = one._tweets[key]
          }
        });
        aclog.tweets.__tweets("tweets/user_favorited_by", Object.assign({ count: 3 }, params)).then(res => {
          one.loadingTweets = false;
          one.tweets = res.statuses;
        });
      }
    },
    failProfileImage: function(e) {
      e.preventDefault();
      e.target.src = "/assets/profile_image_missing.png";
    },
  },
  route: {
    data(tr) {
      var sn = tr.to.params.screen_name;
      aclog.users.favorited_by(sn).then(res => {
        this.user = res.user;
        this.data.$set(0, Object.assign(this.data[0], {
          loading: false,
          users: res.users,
          users_count: res.users_count,
          reactions_count: res.reactions_count,
          showTweets: false,
          tweets: [],
          lastUser: null,
          _permalink: "/" + sn + "/favorited_by/:screen_name",
          _tweets: { screen_name: sn, source_screen_name: ":screen_name" },
        }));
      });
      aclog.users.favorited_users(sn).then(res => {
        this.user = res.user;
        this.data.$set(1, Object.assign(this.data[1], {
          loading: false,
          users: res.users,
          users_count: res.users_count,
          reactions_count: res.reactions_count,
          showTweets: false,
          tweets: [],
          lastUser: null,
          _permalink: "/:screen_name/favorited_by/" + sn,
          _tweets: { screen_name: ":screen_name", source_screen_name: sn },
        }));
      });
    }
  }
};
</script>
