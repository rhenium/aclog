<template>
  <div class="container">
    Authenticating.. (verifying oauth_verifier)
  </div>
</template>

<script>
import aclog from "aclog";

export default {
  route: {
    canReuse() { return false; },
    data(tr) {
      this.$root.updateTitle("Authenticating...");
      aclog.sessions.callback(this.$route.query.oauth_verifier).then(res => {
        const redirect = tr.to.query.redirect_after_login;
        if (redirect && redirect.startsWith("/") && !redirect.indexOf("//")) {
          tr.redirect({ path: redirect, query: null });
        } else {
          tr.redirect({ path: "/" + res.current_user.screen_name, query: null });
        }
      }).catch(err => {
        this.$root.setFlash(err);
        tr.abort();
      });
    },
  }
};
</script>
