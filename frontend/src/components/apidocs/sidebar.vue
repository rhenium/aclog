<template>
  <div class="sidebar">
    <div class="sidebar-list">
      <partial name="loading-box" v-if="loading"></partial>
      <div class="list-group list-group-scroll" v-else>
        <template v-for="(name, namespace) in apidocs">
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
