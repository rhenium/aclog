<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3 col-md-offset-1">
        <div class="sidebar">
          <h1>Optout</h1>
        </div>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <p>オプトアウト設定を完了しました。</p>
        <p><a href="https://twitter.com/settings/applications">https://twitter.com/settings/applications</a> から "aclog collector" のアクセス許可を取り消すことができます。</p>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";
import storage from "storage";

export default {
  route: {
    canReuse() { return false; },
    canActivate() { return !storage.isLoggedIn(); },
    activate(tr) {
      aclog.optout.callback(this.$route.query.oauth_verifier).then(res => {
        tr.next({});
      }).catch(err => {
        // TODO: flash message?
        tr.redirect("/");
      });
    },
  },
};
</script>
