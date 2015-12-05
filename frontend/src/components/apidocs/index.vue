<template>
  <h1>API Documentation</h1>
  <p>Aclog の全機能が使える API を提供しています。</p>
  <p>Aclog API で取得できるデータにはツイート本文やユーザーの名前等は含まれませんが、これは Twitter API 規約の制約によるものですのでご了承ください。</p>
  <h2>基本的な使い方</h2>
  <p>現在の Aclog API のエンドポイントの呼び出しには GET メソッドを使用します。</p>
  <p>curl を使用する場合、以下のように呼び出すことができます。</p>
  <pre><code>curl -v \&#x000A;     --get http://aclog.koba789.com/api/tweets/user_timeline.json \&#x000A;     --data screen_name=rhe__ \&#x000A;     --data count=2&#x000A;</code></pre>
  <h2>認証</h2>
  <p>ツイートを非公開にしているアカウントの情報にアクセスするには本人であるか、対象のアカウントをフォローしている必要があります。</p>
  <p>Aclog API では OAuth Echo を使用します。OAuth Echo を使用するには、API リクエスト時のヘッダに以下の 2 つを追加します。</p>
  <pre><code>X-Auth-Service-Provider: https://api.twitter.com/1.1/account/verify_credentials.json&#x000A;X-Verify-Credentials-Authorization: [account/verify_credentials を呼び出しに使う Authorization ヘッダの内容]</code></pre>
  OAuth Echo の詳細については<a href="https://dev.twitter.com/oauth/echo">Twitter のドキュメント</a>を参照してください。
  <h2>エラー</h2>
  <p>Aclog API の呼び出しでエラーが発生した場合、レスポンスのステータスコードは 400 番台もしくは 500 番台となり、以下のフォーマットのレスポンスボディが返されます。</p>
  <pre><code>{&#x000A;  "error": {&#x000A;    "message": "That page does not exists."&#x000A;  }&#x000A;}</code></pre>
  <p>Aclog API で発生するエラーには以下の種類があります。</p>
  <table class="table">
    <tbody>
      <tr>
        <td>ステータスコード 404</td>
        <td>存在しない API を呼び出した場合。または、パラメータとして指定したユーザー・ツイートが Aclog のデータベース上に存在しない場合</td>
      </tr>
      <tr>
        <td>ステータスコード 403</td>
        <td>ツイートを非公開にしているユーザーに関して API を呼び出した場合で、自分が相手をフォローしていないか OAuth Echo を使用していない場合。</td>
      </tr>
      <tr>
        <td>ステータスコード 401</td>
        <td>OAuth Echo に失敗した場合。</td>
      </tr>
      <tr>
        <td>ステータスコード 500</td>
        <td>Aclog の内部エラー。Aclog の不具合です。</td>
      </tr>
    </tbody>
  </table>
</template>

<script>
export default { };
</script>
