<template>
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
      <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '3m' }) }">3m</a>
      <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1w' }) }">1w</a>
    </div>
    <div class="list-group-col">
      <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1y' }) }">1y</a>
      <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1m' }) }">1m</a>
      <a class="list-group-item" v-link="{ exact: true, name: jumpBase, params: fixParams({ recent: '1d' }) }">1d</a>
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
</template>

<script>
import aclog from "aclog";

export default {
  data() {
    return {
      query: "",
    };
  },
  computed: {
    jumpBase: function() {
      return this.$route.name.replace(/-top$/, "");
    }
  },
  methods: {
    fixParams: function(params) {
      return Object.assign({}, this.$route.params, params);
    },
    submitQuery(e) {
      e.preventDefault();
      this.$route.router.go({ name: "public-filter", query: { q: this.query } });
    },
  },
  created() {
    if (this.$route.query.q) { this.query = this.$route.query.q; }
  }
};
</script>
