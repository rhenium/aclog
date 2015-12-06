<script>
export default {
  replace: false,
  components: { "navbar": require("./navbar.vue") },
  data() {
    return {
      flash: null,
      flashNext: null,
    };
  },
  watch: {
    "$route"(n, o) { // ページ遷移？
      this.flash = null;
      if (this.flashNext) {
        this.flash = this.flashNext;
        this.flashNext = null;
      }
    }
  },
  methods: {
    updateTitle(str) {
      if (str && str !== "") {
        document.title = str + " - aclog";
      } else {
        document.title = "aclog";
      }
    },
    setFlash(obj) {
      if (obj instanceof Error && obj.response) {
        this.flashNext = obj.response.data.error.message;
      } else {
        this.flashNext = obj;
      }
    }
  }
};
</script>
