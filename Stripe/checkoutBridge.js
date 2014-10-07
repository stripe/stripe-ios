window.checkoutJSBridge = {
  prepare: function() {
    var opener = {};
    opener.postMessage = function(blob, _) {
      var message = JSON.parse(blob)
      window.location = "stripecheckout://" + message.method + "?args=" + JSON.stringify(message.args) + "&id=" + message.id;
    };
    window.opener = opener;
  },
  loadOptions: function() {
    var data = JSON.stringify({"method":"render","args":["","tab",%@],"id":1});
    window.postMessage(data, '*');
  },
  frameCallback1: function() {
    var data = JSON.stringify({"method":"open","args":[],"id":2})
    window.postMessage(data, '*');
  }
};
window.checkoutJSBridge.prepare();
