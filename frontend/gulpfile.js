var gulp = require("gulp");
var sass = require("gulp-sass");
var webpack = require("webpack");
var gwebpack = require("webpack-stream");
var WebpackDevServer = require("webpack-dev-server");

gulp.task("default", ["build", "watch"]);
gulp.task("build", ["webpack", "sass", "copy"]);

gulp.task("watch", function(cb) {
  gulp.watch("./src/**/*.scss", function() {
    gulp.start(["sass"]);
  });
  gulp.watch(["./src/index.html", "./src/assets/**"], function() {
    gulp.start(["copy"]);
  });

  var config = Object.create(require("./webpack.config.js"));
  config.entry.app.unshift("webpack-dev-server/client?http://localhost:3001", "webpack/hot/dev-server");
  config.plugins.unshift(new webpack.HotModuleReplacementPlugin());
  new WebpackDevServer(webpack(config), {
    hot: true,
    stats: { colors: true },
    contentBase: "./dest",
    publicPath: "/assets",
    historyApiFallback: true,
  }).listen(3001);
});

gulp.task("copy", function() {
  gulp
    .src(["./src/index.html", "./src/assets/**"], { base: "./src" })
    .pipe(gulp.dest("./dest"));
});

gulp.task("sass", ["bootstrap"], function() {
  gulp
    .src("./src/stylesheets/**/*.scss")
    .pipe(sass().on("error", sass.logError))
    .pipe(gulp.dest("./dest/assets"));
});

gulp.task("bootstrap", function() {
  gulp
    .src("./node_modules/bootstrap-sass/assets/fonts/bootstrap/**")
    .pipe(gulp.dest("./dest/assets/bootstrap/fonts"));
});

gulp.task("webpack", function() {
  gulp
    .src("./src/app.js")
    .pipe(gwebpack(require("./webpack.config.js"), webpack))
    .pipe(gulp.dest("./dest/assets"));
});
