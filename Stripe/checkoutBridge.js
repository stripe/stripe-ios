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
    var data = JSON.stringify({"method":"render","args":["","tab",{"timeLoaded":1410834790,"key":"pk_Fhlzwtm9SCx6Uxww5fNXX8CUbwwAc","amount":"2500","name":"Dribbble","description":"Pro Plan","currency":"usd","image":"http://f.cl.ly/items/1a0V0M1i3Y1M3A3N1U3O/dribbble.png","label":"Pay with Card", "allowRememberMe":false}],"id":1});
    window.postMessage(data, '*');
  },
  frameCallback1: function() {
    var data = JSON.stringify({"method":"open","args":[],"id":2})
    window.postMessage(data, '*');
  }
};
window.checkoutJSBridge.prepare();
