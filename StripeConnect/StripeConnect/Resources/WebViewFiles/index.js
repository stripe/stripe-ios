var stripeConnectInstance;
var component;

window.StripeConnect = window.StripeConnect || {};

// Delete me – this just allows us to debug in chrome without erroring
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

const debug = (message) => {
    // Log to xcode
    window.webkit.messageHandlers.debug.postMessage(message);
    // Log to browser console
    console.debug(message);
};

// This gets set to the promise resolve when `fetchClientSecret` is called.
// Swift will send the client secret to this method when it's done retrieving it.
var resolveFetchClientSecret = (secret) => {
    debug('didFinishFetchingClientSecret');
};

const fetchClientSecret = async () => {
    debug("fetchClientSecret");
    // Message Swift that we want to start fetching the secret. 
    // Swift will call `resolveFetchClientSecret` when it's finished.
    // Note: Swift requires that the `postMessage` body be non-empty for it to work
    window.webkit.messageHandlers.beginFetchClientSecret.postMessage('');

    // Delete me – allows for debugging in chrome with hardcoded secret
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
    debug(secret);
    return secret;
};

// delete me - test method to debug Swift -> JS communication
const test = () => {
    window.webkit.messageHandlers.debug.postMessage("test");
};

StripeConnect.onLoad = () => {

    let searchParams = new URLSearchParams(window.location.search);
    let publishableKey = searchParams.get('publishableKey');
    let componentType = searchParams.get('componentType');

    debug("PK " + publishableKey);

    stripeConnectInstance = StripeConnect.init({
        publishableKey: publishableKey,
        fetchClientSecret: fetchClientSecret,
    });

    component = stripeConnectInstance.create(componentType);

    debug(component.outerHTML);
    document.body.appendChild(component);
};
