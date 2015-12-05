var self = {
  close(e) {
    Array.prototype.forEach.call(document.querySelectorAll("[data-toggle=dropdown]"), (elm) => {
      var parent = elm.parentElement;
      if (!parent.classList.contains("open")) return;
      if (e && e.type == "click" && /input|textarea/i.test(e.target.tagName) && parent.contains(e.target)) return;

      parent.classList.remove("open");
    });
  },
  toggle(e) {
    self.close(e);

    for (var elm = e.target; elm; elm = elm.parentElement) {
      if (elm.getAttribute("data-toggle") === "dropdown") {
        e.preventDefault();
        elm.parentElement.classList.add("open");
        break;
      }
    }
  },
  registerEvents() {
    document.addEventListener("click", self.toggle, true);
  },
  unregisterEvents() {
    document.removeEventListener("click", self.toggle, true);
  },
};

export default self;
