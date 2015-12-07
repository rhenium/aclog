<template>
  <div class="container">
    <div class="row" v-else>
      <div class="col-sm-3 col-md-offset-1">
        <sidebar-user v-bind:user="user"></sidebar-user>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <div class="statuses" v-el:tweets>
          <tweet v-for="tweet in statuses" v-bind:tweet="tweet"></tweet>
          <partial name="loading-box" v-if="loading"></partial>
          <div class="refresh-box" v-else><a v-on:click="refresh" href="#" title="Refresh"><span class="glyphicon glyphicon-refresh" /></a></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";
import Utils from "utils";
import SidebarUser from "components/sidebar/user.vue";

export default {
  components: {
    "sidebar-user": SidebarUser
  },
  data() {
    return {
      statuses: [],
      user: { screen_name: this.$route.params.screen_name, profile_image_url: "/assets/loading.gif", registered: true },
      loading: true,
    };
  },
  methods: {
    refresh(e) {
      e.preventDefault();
      this.loading = true;
      aclog.tweets.update(this.$route.params.id).then(res => {
        this.statuses = res.statuses;
        this.user = res.user;
        this.loading = false;
      }).catch(err => this.$root.setFlash(err));
    },
  },
  route: {
    data(transition) {
      this.$root.updateTitle("Loading...");
      aclog.tweets.show(this.$route.params.id).then(res => {
        var tweet = res.statuses.find(st => st.id_str === this.$route.params.id);
        this.$root.updateTitle('"' + Utils.truncateString(tweet.text, 30) + '" from @' + res.user.screen_name);
        transition.next({
          statuses: res.statuses,
          user: res.user,
          loading: false
        });
      }).catch(err => {
        this.$root.setFlashNext(err);
        transition.abort();
      });
    },
  },
};
</script>
