<template>
  <div class="status" v-bind:class="{ 'status-reply': tweet.aside }" v-if="tweet.allowed">
    <div class="status-tweet">
      <div class="status-user">
        <profile-image v-bind:user="tweet.user"></profile-image>
      </div>
      <div class="status-content">
        <div class="status-head">
          <span class="user"><a v-link="'/' + tweet.user.screen_name"><span v-text="tweet.user.name"></span> <span v-text="'@' + tweet.user.screen_name"></span></a></span>
          <span class="time"><a v-link="'/i/' + tweet.id_str" title="このツイートの詳細を見る"><time v-bind:datetime="tweet.tweeted_at" v-text="formattedTweetedAt"></time></a> <a class="source aclogicon aclogicon-twitter" href="https://twitter.com/{{tweet.user.screen_name}}/status/{{tweet.id_str}}" title="Twitter で見る" target="_blank"></a></span>
        </div>
        <div class="status-text">{{{formattedText}}}</div>
        <div class="status-media" v-if="hasMedia">
          <div v-for="mediaItem in media">
            <video v-if="mediaItem.isVideo" v-bind:src="mediaItem.url" controls></video>
            <a v-else v-bind:href="mediaItem.url" target="_blank"><img alt="img" v-bind:src="mediaItem.url"></a>
          </div>
        </div>
        <div class="status-foot">
          <span class="source">{{{formattedSource}}}</span>
          <ul>
            <li><a class="aclogicon aclogicon-like" v-on:click="openIntent" href="https://twitter.com/intent/favorite?tweet_id={{tweet.id_str}}" title="いいね！"></a></li>
            <li><a class="aclogicon aclogicon-retweet" v-on:click="openIntent" href="https://twitter.com/intent/retweet?tweet_id={{tweet.id_str}}" title="リツイート"></a></li>
            <li><a class="aclogicon aclogicon-reply" v-on:click="openIntent" href="https://twitter.com/intent/tweet?in_reply_to={{tweet.id_str}}" title="返信"></a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="status-responses">
      <dl v-if="tweet.favorites_count &gt; 0">
        <dt>
        <a class="expand-responses-button" v-on:click="toggleExpandFavorites" href="#" title="すべて見る"><span v-text="tweet.favorites_count"></span>Likes</a>
        </dt>
        <dd v-bind:class="{ 'collapsed': !expandFavorites }">
        <ul class="status-responses-favorites">
          <li v-if="loading">
            <img class="loading-image" src="/assets/loading.gif" />
          </li>
          <li v-for="user in tweet.favorites" track-by="$index">
            <partial name="profile-image" v-if="user"></partial>
            <img alt="protected user" v-else src="/assets/profile_image_protected.png" />
          </li>
        </ul>
        </dd>
      </dl>
      <dl v-if="tweet.retweets_count &gt; 0">
        <dt>
        <a class="expand-responses-button" v-on:click="toggleExpandRetweets" href="#" title="すべて見る"><span v-text="tweet.retweets_count"></span>RTs</a>
        </dt>
        <dd v-bind:class="{ 'collapsed': !expandRetweets }">
        <ul class="status-responses-retweets">
          <li v-if="loading">
            <img class="loading-image" src="/assets/loading.gif" />
          </li>
          <li v-for="user in tweet.retweets" track-by="$index">
            <partial name="profile-image" v-if="user"></partial>
            <img alt="protected user" v-else src="/assets/profile_image_protected.png" />
          </li>
        </ul>
        </dd>
      </dl>
    </div>
  </div>
  <div class="status" v-bind:class="{ 'status-reply': tweet.aside }" v-else>
    <div class="status-tweet">
      <div class="status-user">
        <img alt="protected user" src="/assets/profile_image_protected.png" />
      </div>
      <div class="status-content">
        <div class="status-head">
          <span class="time">
            <time v-bind:datetime="tweet.tweeted_at" v-text="formattedTweetedAt"></time>
            <a class="source aclogicon aclogicon-twitter" v-if="tweet.id_str" href="https://twitter.com/{{tweet.user.screen_name}}/status/{{tweet.id_str}}" title="Twitter で見る" target="_blank"></a>
            <div class="source aclogicon aclogicon-twitter" v-else></div>
          </span>
        </div>
        <div class="status-text protected">ツイートは非公開に設定されています</div>
        <div class="status-foot"></div>
      </div>
    </div>
  </div>
</template>

<script>
import aclog from "aclog";
import twitterText from "twitter-text";
import Utils from "utils";
import moment from "moment";

export default {
  props: ["tweet"],
  data() {
    return {
      expandFavorites: false,
      expandRetweets: false,
      loading: false,
      media: null,
    };
  },
  computed: {
    formattedTweetedAt() {
      return moment(this.tweet.tweeted_at).format("YYYY-MM-DD HH:mm:ss");
    },
    formattedText() {
      if (this.media === null) this.initMediaUrls();
      const str = this.tweet.text;
      var autolinked = twitterText.autoLink(str, {
        suppressLists: true,
        usernameIncludeSymbol: true,
        usernameUrlBase: "/"
      });
      return autolinked.replace(/\r?\n/g, "<br />\n");
    },
    formattedSource() {
      const str = this.tweet.source;
      if (/^<a href="([^"]+?)" rel="nofollow">([^<>]+?)<\/a>$/.test(str)) {
        return str.replace(/&/g, "&amp;");
      } else {
        return Utils.escapeHTML(str);
      }
    },
    hasMedia() {
      if (this.media === null) this.initMediaUrls();
      return this.media.length > 0
    },
    mediaUrls() {
      if (this.media === null) this.initMediaUrls();
      return this.media;
    }
  },
  methods: {
    initMediaUrls() {
      const orig = this.tweet.text;
      const media = [];
      this.tweet.text = orig.replace(/\s?(https?:\/\/(pbs|video)\.twimg\.com\/[-\/_A-Za-z0-9]+\.(png|jpg|jpeg|mp4|gif))/gi, (match, p1) => {
        media.push({ url: p1, isVideo: p1.endsWith("mp4") });
        return "";
      });
      this.media = media;
    },
    toggleExpandFavorites(e) {
      e.preventDefault();
      this.expandFavorites = !this.expandFavorites;
    },
    toggleExpandRetweets(e) {
      e.preventDefault();
      this.expandRetweets = !this.expandRetweets;
    },
    openIntent(e) {
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
    updateReactions() {
      if (!this.tweet.allowed || this.tweet.reactions_count === 0 || this.loading) return;
      this.loading = true;
      aclog.tweets.responses(this.tweet.id_str).then(res => {
        this.$set("tweet.favorites", res.favorites);
        this.$set("tweet.retweets", res.retweets);
        this.$set("tweet.include_reactions", true);
        this.loading = false;
      }).catch(err => {
        // should not fail
        this.$root.setFlash(err);
        this.loading = false;
      });
    },
  },
  ready() {
    if (!this.tweet.include_reactions) {
      this.updateReactions();
    }
  },
};
</script>
