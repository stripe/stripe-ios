var stripeConnectInstance;
var component;

window.StripeConnect = window.StripeConnect || {};
window.webkit = window.webkit || {
    'messageHandlers': {
        'debug': {
            'postMessage': () => {}
        },
        'fetchClientSecret': {
            'postMessage': () => {}
        }
    }
};

// This gets set to the promise resolve when `fetchClientSecret` is called.
// Swift will send the client secret to this method when it's done retrieving it.
var resolveFetchClientSecret = (secret) => {
    window.webkit.messageHandlers.debug.postMessage('didFinishFetchingClientSecret');
};

const fetchClientSecret = async () => {
    window.webkit.messageHandlers.debug.postMessage("fetchClientSecret");
    window.webkit.messageHandlers.fetchClientSecret.postMessage('');

    // Debug - delete me
    let searchParams = new URLSearchParams(window.location.search);
    let queryParamSecret = searchParams.get('clientSecret');
    if (queryParamSecret) {
        return queryParamSecret
    }
    // End deleteme

    const promise = new Promise((resolve, reject) => {
        resolveFetchClientSecret = resolve;
    });

    const secret = await promise;
    window.webkit.messageHandlers.debug.postMessage(secret);
    return secret;
};

const test = () => {
    window.webkit.messageHandlers.debug.postMessage("test");
};

StripeConnect.onLoad = () => {

    let searchParams = new URLSearchParams(window.location.search);
    let publishableKey = searchParams.get('publishableKey');
    let componentType = searchParams.get('componentType');

    window.webkit.messageHandlers.debug.postMessage("PK " + publishableKey);

    stripeConnectInstance = StripeConnect.init({
        publishableKey: publishableKey,
        fetchClientSecret: fetchClientSecret,
    });

    component = stripeConnectInstance.create(componentType);
    document.body.appendChild(component);
};

window.webkit.messageHandlers.debug.postMessage("poo");
