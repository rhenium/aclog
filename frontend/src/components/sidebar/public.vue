<template>
  <div class="sidebar">
    <h1>All</h1>
    <div class="sidebar-flex">
      <div class="list-group">
        <a class="list-group-item" v-link="{ name: 'public-best-top' }">Best</a>
        <a class="list-group-item" v-link="{ name: 'public-timeline-top' }">Timeline</a>
      </div>
      <sidebar-filtering></sidebar-filtering>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";
import SidebarFiltering from "components/sidebar/filtering.vue";

export default {
  components: { "sidebar-filtering": SidebarFiltering },
  data() {
    return {
    };
  }
};
</script>
