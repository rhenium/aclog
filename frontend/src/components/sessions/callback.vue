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
    canActivate() {
      return !storage.isLoggedIn();
    },
    data(tr) {
      aclog.sessions.callback(this.$route.query.oauth_verifier).then(res => {
        const redirect = tr.to.query.redirect_after_login;
        if (redirect.startsWith("/") && !redirect.index("//")) {
          tr.redirect(redirect);
        } else {
          tr.redirect("/" + res.current_user.screen_name);
        }
      }).catch(err => {
        // TODO: flash message?
        tr.redirect("/");
      });
    },
  }
};
</script>
