<template>
  <div class="status" v-bind:class="{ 'status-reply': tweet.aside }">
    <div class="status-tweet" v-if="tweet.allowed">
      <div class="status-user">
        <a v-link="'/' + tweet.user.screen_name" title="{{tweet.user.name | removeInvalidCharacters}} (@{{tweet.user.screen_name}})"><img alt="@{{tweet.user.screen_name}}" class="twitter-icon" v-bind:src="tweet.user.profile_image_url" v-on:error="failProfileImage" /></a>
      </div>
      <div class="status-content">
        <div class="status-head">
          <span class="user"><a v-link="'/' + tweet.user.screen_name"><span>{{tweet.user.name | removeInvalidCharacters}}</span>
              <span>@{{tweet.user.screen_name}}</span></a></span>
          <span class="time"><a v-link="'/i/' + tweet.id_str" title="このツイートの詳細を見る"><time datetime="{{tweet.tweeted_at}}">{{tweet.tweeted_at | toLocaleString}}</time></a>
            <a class="source aclogicon aclogicon-twitter" href="https://twitter.com/{{tweet.user.screen_name}}/status/{{tweet.id_str}}" title="Twitter で見る"></a></span>
        </div>
        <div class="status-text">{{{tweet.text | removeInvalidCharacters | formatText}}}</div>
        <div class="status-foot">
          <span class="source">{{{tweet.source | removeInvalidCharacters | formatSource}}}</span>
          <ul>
            <li><a class="aclogicon aclogicon-fav" v-on:click="openIntent" href="https://twitter.com/intent/favorite?tweet_id={{tweet.id_str}}" title="お気に入り登録"></a></li>
            <li><a class="aclogicon aclogicon-retweet" v-on:click="openIntent" href="https://twitter.com/intent/retweet?tweet_id={{tweet.id_str}}" title="リツイート"></a></li>
            <li><a class="aclogicon aclogicon-reply" v-on:click="openIntent" href="https://twitter.com/intent/tweet?in_reply_to={{tweet.id_str}}" title="返信"></a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="status-responses" v-if="tweet.allowed">
      <dl v-if="tweet.favorites_count &gt; 0">
        <dt>
        <a class="expand-responses-button" v-on:click="toggleExpandFavorites" href="#" title="すべて見る"><span>{{tweet.favorites_count}}</span>Favs</a>
        </dt>
        <dd v-bind:class="{ 'collapsed': !expandFavorites }">
        <ul class="status-responses-favorites">
          <li v-if="loading">
            <img class="loading-image" src="/assets/loading.gif" />
          </li>
          <li v-for="user in tweet.favorites">
            <a v-if="user.allowed" v-link="'/' + user.screen_name" title="{{user.name | removeInvalidCharacters}} (@{{user.screen_name}})"><img alt="@{{user.screen_name}}" class="twitter-icon" v-bind:src="user.profile_image_url" v-on:error="failProfileImage" /></a>
            <img alt="protected user" v-if="!user.allowed" src="/assets/profile_image_protected.png" />
          </li>
        </ul>
        </dd>
      </dl>
      <dl v-if="tweet.retweets_count &gt; 0">
        <dt>
        <a class="expand-responses-button" v-on:click="toggleExpandRetweets" href="#" title="すべて見る"><span>{{tweet.retweets_count}}</span>RTs</a>
        </dt>
        <dd v-bind:class="{ 'collapsed': !expandRetweets }">
        <ul class="status-responses-retweets">
          <li v-if="loading">
            <img class="loading-image" src="/assets/loading.gif" />
          </li>
          <li v-for="user in tweet.retweets">
            <a v-if="user.allowed" v-link="'/' + user.screen_name" title="{{user.name | removeInvalidCharacters}} (@{{user.screen_name}})"><img alt="@{{user.screen_name}}" class="twitter-icon" v-bind:src="user.profile_image_url" v-on:error="failProfileImage" /></a>
            <img alt="protected user" v-if="!user.allowed" src="/assets/profile_image_protected.png" />
          </li>
        </ul>
        </dd>
      </dl>
    </div>
    <div class="status-tweet" v-if="!tweet.allowed">
      <div class="status-user">
        <img alt="protected user" src="/assets/profile_image_protected.png" />
      </div>
      <div class="status-content">
        <div class="status-head">
          <span class="time">
            <time datetime="{{tweet.tweeted_at}}">{{tweet.tweeted_at | toLocaleString}}</time>
            <a class="source aclogicon aclogicon-twitter" v-if="tweet.id_str" href="https://twitter.com/{{tweet.user.screen_name}}/status/{{tweet.id_str}}" title="Twitter で見る"></a>
            <div class="source aclogicon aclogicon-twitter" v-if="!tweet.id_str"></div>
          </span>
        </div>
        <div class="status-text protected">ツイートが非公開に設定されているため表示されません</div>
        <div class="status-foot"></div>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";
import twitterText from "twitter-text";

export default {
  props: ["tweet"],
  data: function() {
    return {
      expandFavorites: false,
      expandRetweets: false,
      loading: false,
    };
  },
  filters: {
    formatSource: function(str) {
      if (/^<a href="([^"]+?)" rel="nofollow">([^<>]+?)<\/a>$/.test(str)) {
        return str.replace(/&/g, "&amp;");
    } else {
      return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }
    },
    formatText: function(str) {
      var autolinked = twitterText.autoLink(str, {
        suppressLists: true,
        usernameIncludeSymbol: true,
        usernameUrlBase: "/"
      });
      return autolinked.replace(/\r?\n/g, "<br />\n");
    }
  },
  methods: {
    failProfileImage: function(e) {
      e.preventDefault();
      e.target.src = "/assets/profile_image_missing.png";
    },
    toggleExpandFavorites: function(e) {
      e.preventDefault();
      this.expandFavorites = !this.expandFavorites;
    },
    toggleExpandRetweets: function(e) {
      e.preventDefault();
      this.expandRetweets = !this.expandRetweets;
    },
    openIntent: function(e) {
      e.preventDefault();
      var w = 550;
      var h = 420;
      var sh = window.screen.height;
      var sw = window.screen.width;
      var left = Math.round(sw / 2 - w / 2);
      var top = sh > h && Math.round(sh / 2 - h / 2) || 0;
      var options = "scrollbars=yes, resizable=yes, toolbar=no, location=yes, width=" + w + ", height=" + h + ", left=" + left + ", top=" + top;
      window.open(e.target.getAttribute("href"), null, options);
    },
    updateReactions: function() {
      if (!this.tweet.allowed || this.tweet.reactions_count == 0) { return; }
      aclog.tweets.responses(this.tweet.id_str).then(res => {
        this.$set("tweet.favorites", res.favorites);
        this.$set("tweet.retweets", res.retweets);
        this.loading = false;
      });
    },
  },
  ready: function() {
    if (!this.tweet.include_reactions) {
      this.updateReactions();
    }
  },
};
</script>
