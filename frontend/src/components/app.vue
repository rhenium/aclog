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
      title: "aclog",
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
      var newStr;
      if (str && str !== "") {
        newStr = str + " - aclog";
      } else {
        newStr = "aclog";
      }
      document.title = newStr;
      this.title = newStr;
    },
    setFlash(obj) {
      this.flash = Utils.stringifyMessage(obj);
    },
    setFlashNext(obj) {
      this.flashNext = Utils.stringifyMessage(obj);
    },
  },
  attached() {
    document.querySelector("#app").style.display = "block";
  }
};
</script>
