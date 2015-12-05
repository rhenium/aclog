<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3 col-md-offset-1">
        <sidebar v-bind:user="user"></sidebar>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <div class="statuses" v-el:tweets>
          <tweet v-for="tweet in statuses" v-bind:tweet="tweet"></tweet>
          <div class="loading-box" v-if="loading"><img class="loading-image" src="/assets/loading.gif" /></div>
          <div class="refresh-box" v-else><a v-on:click="refresh" href="#" title="Refresh"><span class="glyphicon glyphicon-refresh" /></a></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";

export default {
  data: function() {
    return {
      statuses: [],
      user: null,
      loading: true,
    };
  },
  methods: {
    load: function(queryString) {
      if (this.loading || (!queryString && !this.next)) { return; }
      this.loading = true;
      aclog.tweets.__tweets(this.$route.api, queryString || this.next).then(json => {
        this.statuses = this.statuses.concat(json.statuses);
        this.user = json.user;
        this.next = json.next;
        this.loading = false;
      }).catch(err => {
        console.log(err);
        // TODO
      });
    },
    refresh(e) {
      e.preventDefault();
      this.loading = true;
      aclog.tweets.update(this.$route.params.id).then(res => {
        this.statuses = res.statuses;
        this.user = res.user;
        this.loading = false;
      });
    },
  },
  route: {
    data(transition) {
      aclog.tweets.show(this.$route.params.id).then(res => {
        transition.next({
          statuses: res.statuses,
          user: res.user,
          loading: false
        });
      }).catch(err => {
        transition.abort();
      });
    },
  },
};
</script>
