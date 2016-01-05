"use strict";

const gulp = require("gulp");
const sass = require("gulp-sass");
const webpack = require("webpack");
const gwebpack = require("webpack-stream");
const WebpackDevServer = require("webpack-dev-server");
const iconfont = require("gulp-iconfont");
const consolidate = require("gulp-consolidate");

gulp.task("default", ["sass", "copy", "watch"]);
gulp.task("build", ["webpack-build", "sass", "copy"]);

gulp.task("watch", (cb) => {
  gulp.watch("./src/**/*.scss", ["sass"]);
  gulp.watch(["./src/index.html", "./src/robots.txt", "./src/assets/**"], ["copy"]);
  gulp.start(["webpack-dev-server"]);
});

gulp.task("copy", () => {
  gulp
    .src(["./src/index.html", "./src/robots.txt", "./src/assets/**"], { base: "./src" })
    .pipe(gulp.dest("./dest"));
});

gulp.task("sass", ["iconfont", "bootstrap"], () => {
  gulp
    .src("./src/stylesheets/app.scss")
    .pipe(sass().on("error", sass.logError))
    .pipe(gulp.dest("./dest/assets"));
});

gulp.task("bootstrap", () => {
  return gulp
    .src("./node_modules/bootstrap-sass/assets/fonts/bootstrap/**")
    .pipe(gulp.dest("./dest/assets/bootstrap/fonts"));
});

gulp.task("webpack-build", () => {
  let config = require("./webpack.config.js");
  config.plugins.unshift(new webpack.optimize.UglifyJsPlugin(), new webpack.optimize.DedupePlugin());
  config.plugins.unshift(new webpack.DefinePlugin({ "process.env": { NODE_ENV: '"production"' } }));
  config.plugins.unshift(new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/));
  gulp
    .src("./src/bootstrap.js")
    .pipe(gwebpack(config, webpack))
    .pipe(gulp.dest("./dest/assets"));
});

gulp.task("webpack-dev-server", () => {
  let config = require("./webpack.config.js");
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

gulp.task("iconfont", () => {
  return gulp
    .src("./src/iconfont/*.svg")
    .pipe(iconfont({
      fontName: "aclog",
      formats: ["ttf", "eot", "svg", "woff"],
      timestamp: Math.round(Date.now() / 1000)
    }))
    .on("glyphs", (glyphs, options) => {
      gulp.src("./src/iconfont/_fonticon.scss")
        .pipe(consolidate("lodash", { glyphs: glyphs }))
        .pipe(gulp.dest("./src/stylesheets/generated/"));
    })
    .pipe(gulp.dest("./dest/assets"));
});
