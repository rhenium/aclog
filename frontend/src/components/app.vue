<script>
export default {
  replace: false,
  components: { "navbar": require("./navbar.vue") },
  methods: {
    updateTitle(str) {
      if (str && str !== "") {
        document.title = str + " - aclog";
      } else {
        document.title = "aclog";
      }
    }
  }
};
</script>
