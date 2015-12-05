<template>
  <div class="container">
    Authenticating.. (redirecting to Twitter)
  </div>
</template>

<script>
import aclog from "aclog";
import storage from "storage";

export default {
  route: {
    canReuse() { return false; },
    canActivate() {
      return !storage.isLoggedIn();
    },
    activate(tr) {
      var callback = location.protocol + "//" + location.host + "/i/callback?redirect_after_login=" + encodeURIComponent(this.$route.query.redirect_after_login);
      aclog.sessions.redirect(callback).then(res => {
        location.href = res.redirect;
      }).catch(err => {
        // TODO: flash message?
        tr.redirect("/");
      });
    },
  },
};
</script>
