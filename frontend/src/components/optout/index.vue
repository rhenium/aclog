<template>
  <div class="container">
    <div class="row">
      <div class="col-sm-3 col-md-offset-1">
        <div class="sidebar">
          <h1>Optout</h1>
        </div>
      </div>
      <div class="col-sm-9 col-md-7 col-lg-6">
        <p>オプトアウト設定をすることで、今後あなたのツイートが aclog に表示されるのを拒否することができます。</p>
        <p>Continue ボタンを押し、OAuth 認証（本人確認のために行います）をすることで設定が完了します。</p>
        <p>設定完了後、<a href="https://twitter.com/settings/applications">https://twitter.com/settings/applications</a> から "aclog collector" のアクセス許可を取り消してください。</p>
        <form v-on:submit="submit">
          <div class="form-group">
            <input class="btn btn-default" type="submit" value="Continue" />
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";

export default {
  methods: {
    submit(e) {
      e.preventDefault();
      var callback = location.protocol + "//" + location.host + "/i/optout/callback";
      aclog.optout.redirect(callback).then(res => {
        location.href = res.redirect;
      });
    },
  }
};
</script>
