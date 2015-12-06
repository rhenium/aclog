export default {
  truncateString(str, len) {
    console.log(str);
    var newStr = str.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
    if (newStr.length > len) {
      return newStr.substring(0, 29) + "…";
    } else {
      return newStr;
    }
  }
};
