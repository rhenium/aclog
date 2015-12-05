import Settings from "../settings";
import Storage from "storage";

var encodeQuery = (params) => {
  if (!params) return "";
  var keys = Object.keys(params);
  if (keys.length === 0) return "";

  return keys.map(key => [key, params[key]].map(encodeURIComponent).join("=")).join("&");
}

var continueRequest = promise => {
  return promise.then(res => res.json().then(json => [res, json])).then(xx => {
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

var get = (endpoint, params) => {
  if (Settings.debug) console.log("[API Request] " + endpoint + " query: " + encodeQuery(params));
  var url = Settings.backendPrefix + "/i/api/" + endpoint + ".json?" + encodeQuery(params);
  return continueRequest(fetch(url, {
    method: "get",
    credentials: "include",
  }));
}

var post = (endpoint, body) => {
  if (Settings.debug) console.log("[API Request] " + endpoint + " body: " + encodeQuery(body));
  var url = Settings.backendPrefix + "/i/api/" + endpoint + ".json";
  return continueRequest(fetch(url, {
    method: "post",
    credentials: "include",
    headers: {
      "content-type": "application/x-www-form-urlencoded; charset=UTF-8"
    },
    body: encodeQuery(Object.assign({ authenticity_token: Storage.store.authenticity_token }, body))
  }));
}

export default {
  users: {
    suggestScreenName: (head) => get("users/suggest_screen_name", { head: head }),
    favorited_by: (sn) => get("users/favorited_by", { screen_name: sn }),
    favorited_users: (sn) => get("users/favorited_users", { screen_name: sn }),
    stats_compact: (sn) => get("users/stats_compact", { screen_name: sn }),
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
    update: (settings) => post("settings/update"),
  }
};
