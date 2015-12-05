<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3 col-md-offset-1">
        <sidebar v-bind:user="user"></sidebar>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <h1 v-if="$route.title">{{$route.title}}</h1>
        <div class="statuses" v-el:tweets>
          <tweet v-for="tweet in statuses" v-bind:tweet="tweet"></tweet>
          <div class="loading-box" v-if="loading">
            <img class="loading-image" src="/assets/loading.gif" />
          </div>
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
      loading: false,
      next: null,
      prev: null,
      scrollListener: null,
    };
  },
  methods: {
    loadNext: function(queryString) {
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
  },
  route: {
    data() {
      this.loadNext(Object.assign({}, this.$route.params, this.$route.query));
      return {
        statuses: [],
        loading: false,
        next: null,
        prev: null,
      };
    },
  },
  ready: function() {
    var content = this.$els.tweets;
    this.scrollListener = () => {
      if ((content.getBoundingClientRect().top + content.clientHeight -  window.innerHeight) < 100) {
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
