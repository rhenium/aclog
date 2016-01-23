import Settings from "../../settings";
import Storage from "storage";
import utils from "utils";

var encodeQuery = params => {
  if (!params) return "";
  var keys = Object.keys(params);
  if (keys.length === 0) return "";

  return keys.map(key => [key, params[key]].map(encodeURIComponent).join("=")).join("&");
}

var request = (method, endpoint, params, body) => {
  if (Settings.debug) console.log("[API Request] " + method + " " + endpoint + " query: " + encodeQuery(params) + " body: " + encodeQuery(body));
  var url = utils.getCurrentBaseUrl() + "/i/api/" + endpoint + ".json";
  var opts = {
    method: method,
    credentials: "include",
    headers: { },
  };

  if (method === "post") {
    opts.headers["content-type"] = "application/x-www-form-urlencoded; charset=UTF-8";
    opts.body = encodeQuery(Object.assign({ authenticity_token: Storage.store.authenticity_token }, body));
  } else {
    url += "?" + encodeQuery(params);
  }

  return fetch(url, opts).then(res => res.json().then(json => [res, json])).then(xx => {
    var [res, json] = xx;
    if (res.status >= 400) {
      var error = new Error(res.statusText);
      error.response = json;
      throw error;
    }

    Storage.update(json);
    return json.data;
  });
};

var get = (endpoint, params) => request("get", endpoint, params, null);
var post = (endpoint, body) => request("post", endpoint, null, body);

export default {
  users: {
    suggestScreenName: (head) => get("users/suggest_screen_name", { head: head }),
    favorited_by: (sn) => get("users/favorited_by", { screen_name: sn }),
    favorited_users: (sn) => get("users/favorited_users", { screen_name: sn }),
    stats_compact: (sn) => get("users/stats_compact", { screen_name: sn }),
    lookup: (sns) => get("users/lookup", { screen_name: sns.join(",") }),
  },
  tweets: {
    __tweets: (url, query) => get(url, query),
    responses: (id_str) => get("tweets/responses", { id: id_str }),
    show: (id_str) => get("tweets/show", { id: id_str }),
    update: (id_str) => post("tweets/update", { id: id_str }),
  },
  about: {
    status: () => get("about/status"),
  },
  sessions: {
    redirect: (callback) => get("sessions/redirect", { oauth_callback: callback }),
    callback: (verifier) => get("sessions/callback", { oauth_verifier: verifier }),
    destroy: () => post("sessions/destroy"),
    verify: () => get("sessions/verify"),
  },
  apidocs: {
    load: () => get("apidocs/all"),
  },
  optout: {
    redirect: (cb) => post("optout/redirect", { oauth_callback: cb }),
    callback: (verifier) => get("optout/callback", { oauth_verifier: verifier }),
  },
  settings: {
    get: () => get("settings/get"),
    update: (settings) => post("settings/update", settings),
  }
};
