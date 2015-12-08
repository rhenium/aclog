<script>
import Utils from "utils";
import Navbar from "components/navbar.vue";

export default {
  replace: false,
  components: { "navbar": Navbar },
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
      this.flash = Utils.stringifyMessage(obj);
    },
    setFlashNext(obj) {
      this.flashNext = Utils.stringifyMessage(obj);
    },
  },
  attached() {
    this.$el.style.display = "block";
  }
};
</script>
