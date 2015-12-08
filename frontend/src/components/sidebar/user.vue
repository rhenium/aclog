<template>
  <div class="sidebar" v-if="!user"><partial name="loading-box"></partial></div>
  <div class="sidebar" v-else>
    <div>
      <p><img alt="@{{user.screen_name}}" class="img-rounded twitter-icon" height="64" v-bind:src="user.profile_image_url" width="64" /></p>
      <p>@{{user.screen_name}}</p>
      <p><a class="aclogicon aclogicon-twitter" href="https://twitter.com/{{user.screen_name}}"></a></p>
      <div class="user-stats">
        <template v-if="user.registered">
          <partial name="loading-box" v-if="!stats"></partial>
          <template v-else>
            <ul class="records">
              <li><span>Received</span><span class="data">{{stats.reactions_count}}</span></li>
              <li><span>Average</span><span class="data">{{average}}</span></li>
              <li><span>Joined</span><span class="data">{{stats.since_join}}<span>d ago</span></span></li>
            </ul>
          </template>
        </template>
        <div class="alert alert-aclog" v-else>@{{user.screen_name}} は aclog に登録していません</div>
      </div>
    </div>
    <div class="sidebar-flex">
      <div class="list-group">
        <a class="list-group-item" v-link="{ exact: true, name: 'user-best-top', params: { screen_name: user.screen_name } }" v-bind:class="{ 'active': $route.name.startsWith('user-best') }">Best</a>
        <a class="list-group-item" v-link="{ name: 'user-timeline-top', params: { screen_name: user.screen_name } }">Timeline</a>
        <a class="list-group-item" v-link="{ name: 'user-favorites-top', params: { screen_name: user.screen_name } }">Likes</a>
        <a class="list-group-item" v-link="{ exact: true, name: 'user-stats', params: { screen_name: user.screen_name } }" v-if="user.registered">Stats</a>
      </div>
      <sidebar-filtering></sidebar-filtering>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";
import SidebarFiltering from "components/sidebar/filtering.vue";

export default {
  props: ["user"],
  components: { "sidebar-filtering": SidebarFiltering },
  data() {
    return {
      stats: null,
    };
  },
  computed: {
    average() {
      return Math.round(this.stats.reactions_count / this.stats.tweets_count * 100) / 100;
    },
    isUserPage() {
      console.log(this.$route);
      return !!this.user || !!this.$route.params.screen_name || this.$route.fullPath === "/i/:id"
    }
  },
  watch: {
    user(newval, oldval) {
      if (newval && newval.registered && (!oldval || newval.id_str !== oldval.id_str)) {
        this.stats = null;
        aclog.users.stats_compact(newval.screen_name).then(res => {
          this.stats = res;
        });
      }
    }
  },
};
</script>
