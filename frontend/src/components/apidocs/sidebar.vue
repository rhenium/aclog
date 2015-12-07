<template>
  <div class="sidebar">
    <div class="sidebar-list">
      <div class="list-group list-group-scroll">
        <a class="list-group-item" v-link="{ path: '/about/api', exact: true }">About API</a>
        <partial name="loading-box" v-if="loading"></partial>
        <template v-for="(name, namespace) in apidocs" v-if="!loading">
          <span class="list-group-head">{{name | capitalize}}</span>
          <a class="list-group-item" v-for="endpoint in namespace" v-link="endpoint_link(endpoint)">{{endpoint_string(endpoint)}}</a>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";

export default {
  data() {
    return {
      apidocs: {},
      loading: false,
    };
  },
  methods: {
    endpoint_link(endpoint) {
      return "/about/api/" + endpoint.method.toLowerCase() + "/" + endpoint.path;
    },
    endpoint_string(endpoint) {
      return endpoint.method + " " + endpoint.path;
    },
  },
  created() {
    this.loading = true;
    aclog.apidocs.load().then(docs => {
      this.loading = false;
      this.apidocs = docs.namespaces
    });
  }
};
</script>
