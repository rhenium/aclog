export default {
  truncateString(str, len) {
    var newStr = str.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
    if (newStr.length > len) {
      return newStr.substring(0, 29) + "…";
    } else {
      return newStr;
    }
  },
  stringifyMessage(obj) {
    var str = obj;
    if (obj instanceof Error && obj.response) {
      str = obj.response.data.error.message;
    }
    return str;
  },
  escapeHTML(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  },
};
