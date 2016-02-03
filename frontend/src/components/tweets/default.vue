<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3 col-md-offset-1">
        <sidebar-user v-bind:user="user" v-if="isUserPage"></sidebar-user>
        <sidebar-public v-else></sidebar-public>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <div class="statuses" v-el:tweets>
          <tweet v-for="tweet in statuses" v-bind:tweet="tweet" v-bind:list-idx="$index"></tweet>
          <partial name="loading-box" v-if="loading"></partial>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";
import SidebarUser from "components/sidebar/user.vue";
import SidebarPublic from "components/sidebar/public.vue";

export default {
  components: {
    "sidebar-user": SidebarUser,
    "sidebar-public": SidebarPublic
  },
  data() {
    return {
      statuses: [],
      user: null,
      loading: false,
      next: null,
      prev: null,
      scrollListener: null,
    };
  },
  computed: {
    isUserPage() {
      return !this.$route.fullPath.startsWith("/i/public"); // TODO: kakkowarui
    }
  },
  methods: {
    loadNext() {
      if (this.loading || !this.next) return;
      this.loading = true;
      aclog.tweets.__tweets(this.$route.api, this.next).then(json => {
        this.loading = false;
        this.statuses = this.statuses.concat(json.statuses);
        this.user = json.user;
        this.next = json.next;
      }).catch(err => {
        this.loading = false;
        console.log(err);
        // TODO
      });
    },
  },
  route: {
    data(transition) {
      this.$root.updateTitle(Object.keys(this.$route.params).reduce((p, c) => p.replace(":" + c, this.$route.params[c]), this.$route.title));
      if (this.isUserPage && (this.user === null || this.user.screen_name !== this.$route.params.screen_name)) {
        this.user = { screen_name: this.$route.params.screen_name, profile_image_url: "/assets/loading.gif", registered: true };
      }
      this.statuses = [];
      this.loading = true;
      this.prev = this.next = null;
      aclog.tweets.__tweets(this.$route.api, Object.assign({}, this.$route.params, this.$route.query)).then(res => {
        transition.next({
          user: res.user,
          next: res.next,
          prev: res.prev,
          statuses: res.statuses,
          loading: false
        });
      }).catch(err => {
        this.$root.setFlashNext(err);
        transition.abort();
      });
    },
  },
  ready: function() {
    var content = this.$els.tweets;
    this.scrollListener = () => {
      if ((content.getBoundingClientRect().top + content.clientHeight - window.innerHeight) < 100) {
        this.loadNext();
      }
    };
    window.addEventListener("scroll", this.scrollListener, false);
  },
  beforeDestroy: function() {
    window.removeEventListener("scroll", this.scrollListener, false);
  },
};
</script>
