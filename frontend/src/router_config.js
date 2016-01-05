import Vue from "vue";

import AboutIndexPage from "./components/about/index.vue";
import AboutStatusPage from "./components/about/status.vue";
import TweetsPage from "./components/tweets/default.vue";
import TweetDetailPage from "./components/tweets/show.vue";
import UsersStatsPage from "./components/users/stats.vue";
import SessionsLoginPage from "./components/sessions/login.vue";
import SessionsCallbackPage from "./components/sessions/callback.vue";
import ApidocsIndex from "./components/apidocs/index.vue";
import ApidocsEndpoint from "./components/apidocs/endpoint.vue";
import SettingsPage from "./components/settings/index.vue";
import OptoutPage from "./components/optout/index.vue";
import OptoutCallbackPage from "./components/optout/callback.vue";
import NotFoundPage from "./components/errors/not_found.vue";

export default {
  config: {
    history: true,
    saveScrollPosition: true,
    linkActiveClass: "active"
  },
  map: {
    "/": {
      component: AboutIndexPage,
    },
    "/about/status": {
      component: AboutStatusPage,
    },
    "/about/api": {
      component: ApidocsIndex
    },
    "/about/api/:method/*path": {
      component: ApidocsEndpoint
    },
    "/i/login": {
      name: "login",
      component: SessionsLoginPage,
    },
    "/i/callback": {
      name: "login_callback",
      component: SessionsCallbackPage,
    },
    "/i/optout": {
      name: "optout",
      component: OptoutPage,
    },
    "/i/optout/callback": {
      name: "optout_callback",
      component: OptoutCallbackPage,
    },
    "/i/public/filter": {
      name: "public-filter",
      component: TweetsPage,
      title: "Public Timeline",
      api: "tweets/filter",
      filtering: "query",
    },
    "/i/public/best": {
      name: "public-best-top",
      component: TweetsPage,
      title: "Top Tweets",
      api: "tweets/all_best",
      filtering: "time",
      subRoutes: {
        ":recent": { name: "public-best", component: Vue.extend() }
      }
    },
    "/i/public/timeline": {
      name: "public-timeline-top",
      component: TweetsPage,
      title: "Public Timeline",
      api: "tweets/all_timeline",
      filtering: "reactions",
      subRoutes: {
        ":reactions": { name: "public-timeline", component: Vue.extend() }
      }
    },
    "/i/:id": {
      name: "tweet",
      component: TweetDetailPage,
    },
    "/settings": {
      name: "settings",
      component: SettingsPage,
    },
    "/:screen_name": {
      name: "user-best-top",
      component: TweetsPage,
      title: "@:screen_name's Best Tweets",
      api: "tweets/user_best",
      filtering: "time",
      subRoutes: {
        "best/:recent": { name: "user-best", component: Vue.extend() }
      }
    },
    "/:screen_name/timeline": {
      name: "user-timeline-top",
      component: TweetsPage,
      title: "@:screen_name's Timeline",
      api: "tweets/user_timeline",
      filtering: "reactions",
      subRoutes: {
        ":reactions": { name: "user-timeline", component: Vue.extend() }
      }
    },
    "/:screen_name/favorites": {
      name: "user-favorites-top",
      component: TweetsPage,
      title: "@:screen_name's Likes",
      api: "tweets/user_favorites",
      filtering: "reactions",
      subRoutes: {
        ":reactions": { name: "user-favorites", component: Vue.extend() }
      }
    },
    "/:screen_name/favorited_by/:source_screen_name": {
      name: "user-favorited-by-top",
      component: TweetsPage,
      title: "@:screen_name's Tweets favorited by @:source_screen_name",
      api: "tweets/user_favorited_by",
      filtering: "reactions",
      subRoutes: {
        ":reactions": { name: "user-favorited-by", component: Vue.extend() }
      }
    },
    "/:screen_name/stats": {
      name: "user-stats",
      component: UsersStatsPage,
    },
    "*": {
      component: NotFoundPage,
    },
  },
  redirect: {
    "/i/timeline": "/i/public/timeline",
    "/i/best": "/i/public/best",
    "/i/filter": "/i/public/filter",
  }
};
