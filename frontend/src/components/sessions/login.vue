<template>
  <div class="container">
    Authenticating.. (redirecting to Twitter)
  </div>
</template>

<script>
import aclog from "aclog";

export default {
  route: {
    canReuse() { return false; },
    data(tr) {
      this.$root.updateTitle("Authenticating...");
      var callback = location.protocol + "//" + location.host + "/i/callback?redirect_after_login=" + encodeURIComponent(this.$route.query.redirect_after_login);
      aclog.sessions.redirect(callback).then(res => {
        location.href = res.redirect;
      }).catch(err => {
        this.$root.setFlash(err);
      });
    },
  },
};
</script>
