<template>
  <div class="container">
    <h1>Status</h1>
    <h2>Worker Status</h2>
    <div class="alert alert-danger" v-if="error">
      <strong>{{error}}</strong>
    </div>
    <table class="table" v-if="nodes">
      <thead>
        <tr>
          <th>Group</th>
          <th>Worker ID</th>
          <th>Status</th>
          <th>Uptime</th>
        </tr>
      </thead>
      <tbody>
        <template v-for="(index, val) in active_nodes">
          <tr v-if="nodes[val]">
            <td>{{index}}</td>
            <td>#{{val}} ({{tag(val)}})</td>
            <td>Running</td>
            <td>{{uptime(val)}}</td>
          </tr>
          <tr class="danger" v-else>
            <td>{{index}}</td>
            <td>-</td>
            <td>Down</td>
            <td>-</td>
          </tr>
        </template>
        <template v-for="(index, val) in inactive_nodes">
          <tr>
            <td>-</td>
            <td>#{{val}} ({{tag(val)}})</td>
            <td>Idle</td>
            <td>-</td>
          </tr>
        </template>
      </tbody>
    </table>
    <partial name="loading-box" v-if="loading"></partial>
    <div class="refresh-box" v-else>
      <a v-on:click="load" href="#" title="Refresh"><span class="glyphicon glyphicon-refresh" /></a>
    </div>
  </div>
</template>      

<script>
import aclog from "aclog";

export default {
  data() {
    return {
      nodes: {},
      active_nodes: [],
      inactive_nodes: [],
      loading: false,
      error: null,
    };
  },
  methods: {
    tag(i) {
      return this.nodes[i].tag;
    },
    uptime(i) {
      var diff = Math.floor(Date.now() / 1000) - this.nodes[i].activated_at;
      if (diff < 5 * 60) {
        return diff.toString() + " seconds";
      } else if (diff < 5 * 60 * 60) {
        return Math.floor(diff / 60).toString() + " minutes";
      } else if (diff < 48 * 60 * 60) {
        return Math.floor(diff / 60 / 60).toString() + " hours";
      } else {
        return Math.floor(diff / 60 / 60 / 24).toString() + " days";
      }
    },
    load(e) {
      if (e) e.preventDefault();
      this.loading = true;
      aclog.about.status().then(res => {
        this.loading = false;
        this.error = res.error;
        this.nodes = res.nodes;
        this.active_nodes = res.active_nodes;
        this.inactive_nodes = res.inactive_nodes;
      }).catch(err => {
        this.loading = false;
        this.error = "Failed to fetch (" + err + ")";
        this.nodes = this.active_nodes = this.inactive_nodes = null;
      });
    },
  },
  route: {
    data() { // show page before data
      this.$root.updateTitle("Status");
      this.load();
      return {};
    }
  }
};
</script>
