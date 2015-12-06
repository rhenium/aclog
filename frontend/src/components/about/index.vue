<template>
  <div class="front-hero">
    <div class="container">
      <p><img alt="aclog" height="200" src="/assets/logo.png" width="200" /></p>
      <h1>
        aclog
      </h1>
      <div class="tweet-button">
        <a href="https://twitter.com/intent/tweet?text=Twitter+%E5%88%86%E6%9E%90%E3%82%B5%E3%83%BC%E3%83%93%E3%82%B9+-+aclog&amp;url=http%3A%2F%2Faclog.koba789.com%2F" target="_blank">
          <i></i>
          <span>ツイート</span>
        </a>
      </div>
    </div>
  </div>
  <div class="front-feature">
    <div class="container">
      <div class="row">
        <div class="col-sm-6 col-sm-push-6"><img alt="Collect activities automatically" height="200" src="/assets/feature_1.png" width="400" /></div>
        <div class="col-sm-6 col-sm-pull-6">
          <h1>Collect Activities</h1>
          <p>aclog に一度サインアップするだけで、ツイート、お気に入り、リツイートをリアルタイムで自動収集。</p>
        </div>
      </div>
    </div>
  </div>
  <div class="front-feature-right">
    <div class="container">
      <div class="row">
        <div class="col-sm-6"><img alt="Discover topics easily" height="200" src="/assets/feature_2.png" width="400" /></div>
        <div class="col-sm-6">
          <h1>Discover Topics</h1>
          <p>aclog の見やすい UI で、話題のツイートを発見できます。自分のツイートがどれくらい話題になっているかも一目瞭然。</p>
        </div>
      </div>
    </div>
  </div>
  <div class="front-feature">
    <div class="container">
      <div class="row">
        <div class="col-sm-6 col-sm-push-6"><img alt="Protected account is OK" height="200" src="/assets/feature_3.png" width="400" /></div>
        <div class="col-sm-6 col-sm-pull-6">
          <h1>For Protected Users</h1>
          <p>ツイートを非公開にしている方でもご利用いただけます。ツイートはあなたとあなたのフォロワーにしか見えないので安心です。</p>
        </div>
      </div>
    </div>
  </div>
  <div class="front-feature-misc">
    <div class="container">
      <div class="row">
        <div class="col-sm-3">
          <h1>Notification</h1>
          <p>一定数のふぁぼ・RT が集まると、通知アカウントがリプライで通知します。</p>
        </div>
        <div class="col-sm-3">
          <h1>Atom Feeds</h1>
          <p>Atom フィード配信に対応。普段のニュースリーダーで見ることもできます。</p>
        </div>
        <div class="col-sm-3">
          <h1>Aclog API</h1>
          <p>JSON API を用意。Aclog の全機能が使えます。<a v-link="'/about/api'">API ドキュメント</a>をご覧下さい。</p>
        </div>
        <div class="col-sm-3">
          <h1>Open Source</h1>
          <p>Aclog のソースコードは MIT License でライセンスされています。完全なソースコードは <a href="https://github.com/rhenium/aclog">GitHub のリポジトリ</a>で公開されています。</p>
        </div>
      </div>
    </div>
  </div>
  <div class="front-footer">
    <section>
      <a class="aclogicon aclogicon-twitter" href="https://twitter.com/aclog_service" target="_blank"></a>
      <a class="aclogicon aclogicon-github" href="https://github.com/rhenium/aclog" target="_blank"></a>
    </section>
    <section class="contributors">
      <div class="contributor">
        <em>Created by</em>
        <a href="https://twitter.com/{{created_by.screen_name}}" target="_blank"><img alt="@{{created_by.screen_name}}" v-bind:src="created_by.profile_image_url" title="@{{created_by.screen_name}}" /></a>
      </div>
      <div class="contributor">
        <em>Designed by</em>
        <a href="https://twitter.com/{{designed_by.screen_name}}" target="_blank"><img alt="@{{designed_by.screen_name}}" v-bind:src="designed_by.profile_image_url" title="@{{designed_by.screen_name}}" /></a>
      </div>
      <div class="contributor">
        <em>Hosted by</em>
        <a href="https://twitter.com/{{hosted_by.screen_name}}" target="_blank"><img alt="@{{hosted_by.screen_name}}" v-bind:src="hosted_by.profile_image_url" title="@{{hosted_by.screen_name}}" /></a>
      </div>
    </section>
    <section>
      <a v-link="'/about/api'">API</a>
      <a v-link="'/i/optout'">Optout</a>
      <a v-link="'/about/status'">Status</a>
    </section>
  </div>
</template>

<script>
import aclog from "aclog";

export default {
  data() {
    return {
      created_by: { screen_name: "rhe__", profile_image_url: "/assets/loading.gif" },
      designed_by: { screen_name: "aayh", profile_image_url: "/assets/loading.gif" },
      hosted_by: { screen_name: "KOBA789", profile_image_url: "/assets/loading.gif" },
      loaded: false,
    };
  },
  route: {
    data() {
      this.$root.updateTitle("");
      if (this.loaded) return;
      aclog.users.lookup([this.created_by, this.designed_by, this.hosted_by].map(u => u.screen_name)).then(users => {
        this.created_by = users[0];
        this.designed_by = users[1];
        this.hosted_by = users[2];
        this.loaded = true;
      });
    }
  },
  ready() {
    Array.prototype.forEach.call(document.querySelectorAll(".tweet-button a"), function(node) {
      node.onclick = function(e) {
        e.preventDefault();
        var w = 550;
        var h = 420;
        var sh = window.screen.height;
        var sw = window.screen.width;
        var left = Math.round(sw / 2 - w / 2);
        var top = sh > h && Math.round(sh / 2 - h / 2) || 0;
        var options = "scrollbars=yes, resizable=yes, toolbar=no, location=yes, width=" + w + ", height=" + h + ", left=" + left + ", top=" + top;
        window.open(node.getAttribute("href"), null, options);
      };
    });
  }
}
</script>
