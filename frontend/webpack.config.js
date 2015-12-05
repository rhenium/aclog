var webpack = require("webpack");

module.exports = {
  entry: {
    app: ["./src/app.js"]
  },
  output: {
    path: __dirname + "/dest/assets",
    publicPath: "/assets",
    filename: "app.build.js"
  },
  resolve: {
    root: [__dirname + "/src/lib"],
  },
  module: {
    loaders: [
    { test: /\.vue$/, loader: "vue" },
    { test: /\.js$/, exclude: /node_modules/, loader: "babel?presets[]=es2015" },
    { test: /\.(woff|woff2)(\?v=\d+\.\d+\.\d+)?$/, loader: "file?limit=10000&mimetype=application/font-woff" },
    { test: /\.ttf(\?v=\d+\.\d+\.\d+)?$/, loader: "file?limit=10000&mimetype=application/octet-stream" },
    { test: /\.eot(\?v=\d+\.\d+\.\d+)?$/, loader: "file" },
    { test: /\.svg(\?v=\d+\.\d+\.\d+)?$/, loader: "file?limit=10000&mimetype=image/svg+xml" }
    ]
  },
  plugins: [
    new webpack.ProvidePlugin({ fetch: "imports?this=>global!exports?global.fetch!whatwg-fetch" })
  ],
  devtool: "source-map"
};
