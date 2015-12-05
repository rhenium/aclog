<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3 col-md-offset-1">
        <div class="sidebar">
          <h1>Settings</h1>
        </div>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <div class="loading-box" v-if="!settings"><img class="loading-image" src="/assets/loading.gif" /></div>
        <form v-on:submit="submit" v-else>
          <div class="checkbox">
            <input v-model="settings.notification_enabled" type="checkbox" />
            <label for="notification_enabled">リプライ通知を有効にする</label>
          </div>
          <div class="form-group">
            <input class="btn btn-default" type="submit" />
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import Aclog from "aclog";
import Storage from "storage";

export default {
  data() {
    return {
      settings: null,
    };
  },
  methods: {
    submit(e) {
      e.preventDefault();
      Aclog.settings.update(this.settings).then(res => {
        console.log(res);
        this.settings = res;
      });
    },
  },
  route: {
    data(tr) {
      if (Storage.isLoggedIn()) {
        Aclog.settings.get().then(res => {
        console.log(res);
          tr.next({ settings: res });
        });
      } else {
        tr.redirect("/i/login");
      }
    }
  }
};
</script>
