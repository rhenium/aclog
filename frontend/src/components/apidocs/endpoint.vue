<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3">
        <apidocs-sidebar></apidocs-sidebar>
      </div>
      <div class="col-sm-9">
        <partial name="loading-box" v-if="$loadingRouteData"></partial>
        <template v-else>
          <h1>{{endpoint.method}} {{endpoint.path}}</h1>
          <p>{{endpoint.description}}</p>
          <h2>Resource URL</h2>
          <p>{{endpoint.url}}</p>
          <h2>Parameters</h2>
          <table class="table api-params">
            <tbody>
              <tr v-for="(name, param) in endpoint.params">
                <th>{{name}} <small v-if="param.required">required</small></th>
                <td>
                  <p>{{param.description}}</p>
                  <p><b>Type</b>: {{param.type}}
                  </p>
                </td>
              </tr>
            </tbody>
          </table>
          <template v-if="endpoint.example_params">
            <h2>Example Request</h2>
            <p>
            <span>{{endpoint.method}}</span>
            <code>{{example_url}}</code>
            </p>
            <pre><code><partial name="loading-box" v-if="example.loading"></partial>{{example.result}}</code></pre>
          </template>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
import ApidocsSidebar from "./sidebar.vue";
import aclog from "aclog";
import Settings from "../../settings";

export default {
  components: { "apidocs-sidebar": ApidocsSidebar },
  data() {
    return {
      endpoint: null,
      example: { loading: false },
    };
  },
  computed: {
    example_url() {
      var url = Settings.apiPrefix + "/api/" + this.endpoint.path;
      var params = this.endpoint.example_params;
      var keys = Object.keys(params);
      if (keys.length === 0) {
        return url;
      } else {
        return url + ".json?" + keys.map(key => [key, params[key]].map(encodeURIComponent).join("=")).join("&");
      }
    },
  },
  route: {
    data(transition) {
      this.$root.updateTitle(this.$route.params.method.toUpperCase() + " " + this.$route.params.path + " - API Documentation");

      var notFound = (e) => {
        if (e) this.$root.setFlashNext(e);
        transition.abort();
      };

      aclog.apidocs.load().then(docs => {
        const path = this.$route.params.path;
        const ns = path.split("/", 2)[0];
        const es = docs.namespaces[ns];
        if (!es) return notFound();
        const endpoint = es.find(endp => endp.path === path);
        if (!endpoint) return notFound();

        transition.next({ endpoint: endpoint, example: { loading: false, result: null } });
      }).catch(notFound).then(() => {
        this.example.loading = true;
        fetch(this.example_url).then(res => {
          if (res.status >= 400) {
            var err = new Error(res.statusText);
            err.response = res;
            throw err;
          }
          return res.json();
        }).then(body => {
          this.example.loading = false;
          this.example.result = JSON.stringify(body, null, 2);
        }).catch(err => {
          this.example.loading = false;
          this.example.result = "Failed to load example. (" + err + ")";
          if (err.response) {
            err.response.json().then(body => this.example.result += "\n" + JSON.stringify(body, null, 2));
          }
        });
      });
    }
  },
};
</script>
