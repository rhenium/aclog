<template>
  <div class="container">
    Authenticating.. (redirecting to Twitter)
  </div>
</template>

<script>
import aclog from "aclog";
import utils from "utils";

export default {
  route: {
    canReuse() { return false; },
    data(tr) {
      this.$root.updateTitle("Authenticating...");
      const callback = utils.getCurrentBaseUrl() + "/i/callback?redirect_after_login=" + encodeURIComponent(this.$route.query.redirect_after_login);
      aclog.sessions.redirect(callback).then(res => {
        location.href = res.redirect;
      }).catch(err => {
        this.$root.setFlash(err);
      });
    },
  },
};
</script>
