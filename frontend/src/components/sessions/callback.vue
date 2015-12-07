<template>
  <div class="container">
    Authenticating.. (verifying oauth_verifier)
  </div>
</template>

<script>
import aclog from "aclog";
import storage from "storage";

export default {
  route: {
    canReuse() { return false; },
    data(tr) {
      this.$root.updateTitle("Authenticating...");
      aclog.sessions.callback(this.$route.query.oauth_verifier).then(res => {
        const redirect = tr.to.query.redirect_after_login;
        if (redirect && redirect.startsWith("/") && redirect.indexOf("//") == -1) {
          tr.redirect({ path: redirect, query: null });
        } else {
          tr.redirect({ path: "/" + storage.store.currentUser.screen_name, query: null });
        }
      }).catch(err => {
        this.$root.setFlashNext(err);
        tr.abort();
      });
    },
  }
};
</script>
