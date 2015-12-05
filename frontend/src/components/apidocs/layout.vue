<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3">
        <apidocs-sidebar></apidocs-sidebar>
      </div>
      <div class="col-sm-9">
        <router-view></router-view>
      </div>
    </div>
  </div>
  </div>
</template>

<script>
import ApidocsSidebar from "./sidebar.vue";

export default {
  components: {
    "apidocs-sidebar": ApidocsSidebar,
  },
};
</script>
