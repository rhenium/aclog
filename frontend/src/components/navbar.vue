<template>
  <nav class="navbar navbar-static-top">
    <div class="container">
      <div class="nav navbar-nav navbar-left">
        <a class="navbar-brand" v-link="'/'">aclog</a>
      </div>
      <ul class="nav navbar-nav navbar-right">
        <li class="dropdown omittable">
          <a class="dropdown-toggle" data-toggle="dropdown" href="#">
            All
            <span class="caret" />
          </a>
          <ul class="dropdown-menu">
            <li><a v-link="'/i/public/best'">Best</a></li>
            <li><a v-link="'/i/public/timeline'">Timeline</a></li>
            <li class="divider"></li>
            <li><a v-link="'/about/api'">API document</a></li>
            <li><a v-link="'/about/status'">Current status</a></li>
          </ul>
        </li>
        <li class="dropdown omittable">
          <a class="dropdown-toggle" data-toggle="dropdown" v-on:click="focus" href="#">
            User
            <span class="caret" />
          </a>
          <ul class="dropdown-menu">
            <li>
              <form autocomplete="off" v-on:submit="submit">
                <div class="input-group">
                  <input class="form-control" v-el:input v-model="enteredUserName" placeholder="Username" type="text" />
                  <span class="input-group-btn">
                    <button class="btn" type="submit">Go</button>
                  </span>
                </div>
              </form>
            </li>
            <li class="user-jump-suggestion" v-for="user in users">
              <a v-link="'/' + user.screen_name"><img alt="@{{user.screen_name}}" class="twitter-icon" v-bind:src="user.profile_image_url" v-on:error="placeholderImage" /><span>@{{user.screen_name}}</span></a>
            </li>
            <li class="loading-box" v-if="loading">
              <img class="loading-image" src="/assets/loading.gif" />
            </li>
          </ul>
        </li>
        <li class="navbar-initializing" v-if="!initialized"><img class="loading-image" src="/assets/loading.gif" /></li>
        <template v-else>
          <li class="dropdown" v-if="currentUser">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">
              <img alt="@{{currentUser.screen_name}}" class="twitter-icon" v-bind:src="currentUser.profile_image_url" />
              <span class="caret" />
            </a>
            <ul class="dropdown-menu">
              <li><a v-link="{ name: 'user-best-top', params: { screen_name: currentUser.screen_name } }">Best</a></li>
              <li><a v-link="{ name: 'user-timeline-top', params: { screen_name: currentUser.screen_name } }">Timeline</a></li>
              <li><a v-link="{ name: 'user-favorites-top', params: { screen_name: currentUser.screen_name } }">Likes</a></li>
              <li><a v-link="{ name: 'user-stats', params: { screen_name: currentUser.screen_name } }">Stats</a></li>
              <li class="divider"></li>
              <li><a v-link="'/settings'">Settings</a></li>
              <li><a rel="nofollow" v-on:click="logout" href="#">Sign out</a></li>
            </ul>
          </li>
          <li v-else><a class="signup" rel="nofollow" v-link="'/i/login?redirect_after_login=%2F'">Sign in</a></li>
        </template>
      </ul>
    </div>
  </nav>
</template>

<script>
import aclog from "aclog";
import storage from "storage";
import BootstrapHelper from "bootstrap-helper";

export default {
  data() {
    return {
      users: [],
      enteredUserName: "",
      loading: false,
      currentReq: null,
      store: storage.store,
    }
  },
  computed: {
    currentUser() {
      return this.store.currentUser;
    },
    initialized() {
      return !!this.store.authenticity_token;
    }
  },
  methods: {
    focus(e) {
      e.preventDefault();
      setTimeout(() => this.$els.input.focus(), 0);
    },
    submit(e) {
      e.preventDefault();
      if (this.enteredUserName !== "") {
        this.$route.router.go("/" + this.enteredUserName);
      }
    },
    logout(e) {
      e.preventDefault();
      aclog.sessions.destroy().then(res => {
        storage.store.currentUser = null;
      }).catch(err => {
        this.$root.setFlash(err);
      });
    },
  },
  watch: {
    enteredUserName(newVal, oldVal) {
      if (newVal.length == 0 || newVal === oldVal) { return; }
      this.users = [];
      this.loading = true;
      var req = aclog.users.suggestScreenName(newVal).then(res => {
        if (req !== this.currentReq) return; // cancelled
        this.loading = false;
        this.users = res;
      });
      this.currentReq = req;
    },
  },
  ready() {
    BootstrapHelper.registerEvents();
  },
  beforeDestroy() {
    BootstrapHelper.unregisterEvents();
  }
};
</script>
