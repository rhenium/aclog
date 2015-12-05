import { router } from "../app.js";
import aclog from "aclog";

var storage = {
  store: {
    currentUser: null,
    authenticity_token: null,
  },
  isLoggedIn() { return !!this.store.currentUser; },
  init() {
    aclog.sessions.verify();
  },
  update(json) {
    this.store.currentUser = json.current_user;
    this.store.authenticity_token = json.authenticity_token;
  },
};

export default storage;
