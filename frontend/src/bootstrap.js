require("es6-promise").polyfill();

import aclog from "aclog";
import Vue from "vue";
import VueRouter from "vue-router";
import App from "./app";
import RouterConfig from "./router_config";

if (process.env.NODE_ENV !== "production") Vue.config.debug = true;
Vue.use(VueRouter);
Vue.mixin({
  methods: {
    placeholderImage(e) {
      e.preventDefault();
      e.target.src = "/assets/profile_image_missing.png";
    }
  }
});
Vue.component("tweet", require("./components/tweets/tweet.vue"));
Vue.partial("loading-box", '<div class="loading-box"><img class="loading-image" src="/assets/loading.gif" /></div>');
Vue.partial("profile-image", '<a v-link="\'/\' + user.screen_name" title="{{user.name}} (@{{user.screen_name}})"><img alt="@{{user.screen_name}}" class="twitter-icon" v-bind:src="user.profile_image_url" v-on:error="placeholderImage" /></a>');
Vue.component("profile-image", Vue.extend({ props: ["user"], template: '<partial name="profile-image"></partial>' }));

aclog.sessions.verify();

var router = new VueRouter(RouterConfig.config);
router.map(RouterConfig.map);
router.redirect(RouterConfig.redirect);
router.start(App, "html");
