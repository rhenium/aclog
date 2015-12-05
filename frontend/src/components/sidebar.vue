<template>
  <div class="sidebar">
    <div v-if="user">
      <p><img alt="@{{user.screen_name}}" class="img-rounded twitter-icon" height="64" v-bind:src="user.profile_image_url" width="64" /></p>
      <p>@{{user.screen_name}}</p>
      <p><a class="aclogicon aclogicon-twitter" href="https://twitter.com/{{user.screen_name}}"></a></p>
      <div class="user-stats">
        <div class="loading-box" v-if="loading">
          <img class="loading-image" src="/assets/loading.gif" />
        </div>
        <template v-else>
          <ul class="records" v-if="stats.registered">
            <li><span>Received</span><span class="data">{{stats.reactions_count}}</span></li>
            <li><span>Average</span><span class="data">{{average}}</span></li>
            <li><span>Joined</span><span class="data">{{stats.since_join}}<span>d ago</span></span></li>
          </ul>
          <div class="alert alert-aclog" v-else>@{{user.screen_name}} は aclog に登録していません</div>
        </template>
      </div>
    </div>
    <h1 v-else>All</h1>
    <div class="sidebar-flex">
      <div class="list-group" v-if="user">
        <a class="list-group-item" v-link="{ exact: true, name: 'user-best-top', params: { screen_name: user.screen_name } }">Best</a>
        <a class="list-group-item" v-link="{ exact: true, name: 'user-timeline-top', params: { screen_name: user.screen_name } }">Timeline</a>
        <a class="list-group-item" v-link="{ exact: true, name: 'user-favorites-top', params: { screen_name: user.screen_name } }">Favorites</a>
        <a class="list-group-item" v-link="{ exact: true, name: 'user-stats', params: { screen_name: user.screen_name } }">Stats</a>
      </div>
      <div class="list-group" v-else>
        <a class="list-group-item" v-link="{ name: 'public-best-top' }">Best</a>
        <a class="list-group-item" v-link="{ name: 'public-timeline-top' }">Timeline</a>
      </div>
      <div class="list-group" v-if="$route.filtering == 'reactions'">
        <div class="list-group-col">
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ reactions: 0 }) }">0</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ reactions: 3 }) }">3</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ reactions: 50 }) }">50</a>
        </div>
        <div class="list-group-col">
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase + '-top', params: fixParams() }">1</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ reactions: 10 }) }">10</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ reactions: 100 }) }">100</a>
        </div>
      </div>
      <div class="list-group" v-if="$route.filtering == 'time'">
        <div class="list-group-col">
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase + '-top', params: fixParams() }">All Time</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1w' }) }">1w</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '3m' }) }">3m</a>
        </div>
        <div class="list-group-col">
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1d' }) }">1d</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1m' }) }">1m</a>
          <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1y' }) }">1y</a>
        </div>
      </div>
      <div class="list-group" v-if="$route.filtering == 'query'">
        <div class="search-box">
          <form v-on:submit="submitQuery">
            <div class="input-group">
              <input class="form-control" type="text" v-model="query" />
              <div class="input-group-btn">
                <button class="btn btn-primary" type="submit">
                  <span class="glyphicon glyphicon-search"></span>
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";

export default {
  props: ["user"],
  data: function() {
    return {
      stats: null,
      loading: false,
      query: "",
    };
  },
  computed: {
    jumpBase: function() {
      return this.$route.name.replace(/-top$/, "");
    },
    average: function() {
      return Math.round(this.stats.reactions_count / this.stats.tweets_count * 100) / 100;
    },
  },
  methods: {
    fixParams: function(params) {
      return Object.assign({}, this.$route.params, params);
    },
    submitQuery(e) {
      e.preventDefault();
      this.$route.router.go({ name: "public-filter", query: { q: this.query } });
    },
    updateUser(u) {
      this.loading = true;
      aclog.users.stats_compact(newval.screen_name).then(res => {
        this.stats = res;
        this.loading = false;
      });
    }
  },
  watch: {
    user(newval, oldval) {
      if (newval && (!oldval || newval.id != oldval.id)) {
        this.loading = true;
        aclog.users.stats_compact(newval.screen_name).then(res => {
          this.stats = res;
          this.loading = false;
        });
      }
    }
  },
  created() {
    if (this.$route.query.q) { this.query = this.$route.query.q; }
  }
};
</script>
