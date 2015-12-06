<template>
  <div class="container">
    <div class="error-page">
      <h1>404</h1>
      <p>このページは存在しません</p>
    </div>
  </div>
</template>

<script>
export default {
  route: {
    data() {
      this.$root.updateTitle("404");
    }
  }
};
</script>
