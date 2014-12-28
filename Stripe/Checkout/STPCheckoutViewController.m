//
//  STPCheckoutViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//

#import "STPCheckoutViewController.h"
#import "STPCheckoutOptions.h"
#import "STPToken.h"
#import "Stripe.h"
#import "STPColorUtils.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)
#if TARGET_OS_IPHONE
#define STP_VIEW_CLASS UIView
#else
#define STP_VIEW_CLASS NSView
#endif

@protocol STPCheckoutDelegate;

@protocol STPCheckoutWebViewAdapter<NSObject>
@property (nonatomic, weak) id<STPCheckoutDelegate> delegate;
@property (nonatomic, readonly) STP_VIEW_CLASS *webView;
- (void)loadRequest:(NSURLRequest *)request;
- (void)evaluateJavaScript:(NSString *)js;
- (void)cleanup;
@end

@protocol STPCheckoutDelegate<NSObject>
- (void)checkoutAdapterDidStartLoad:(id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapterDidFinishLoad:(id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didTriggerEvent:(NSString *)event withPayload:(NSDictionary *)payload;
- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didError:(NSError *)error;
@end

static NSString *const checkoutOptionsGlobal = @"StripeCheckoutOptions";
static NSString *const checkoutRedirectPrefix = @"/-/";
static NSString *const STPCheckoutURLProtocolRequestScheme = @"beginstripecheckout";
static NSString *const checkoutRPCScheme = @"stripecheckout";
static NSString *const checkoutUserAgent = @"Stripe";
// TODO replace these
static NSString *const checkoutHost = @"localhost:5394";
// static NSString *const checkoutHost = @"checkout.stripe.com";
static NSString *const checkoutURL = @"localhost:5394/v3/ios/index.html";
// static NSString *const checkoutURL = @"checkout.stripe.com/v3/ios";

@interface STPCheckoutURLProtocol : NSURLProtocol<NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@end

#if TARGET_OS_IPHONE

@interface STPCheckoutUIWebViewAdapter : NSObject<STPCheckoutWebViewAdapter, UIWebViewDelegate>
@property (nonatomic) UIWebView *webView;
@end

@interface STPCheckoutWebViewController : UIViewController<STPCheckoutDelegate>

- (instancetype)initWithCheckoutViewController:(STPCheckoutViewController *)checkoutViewController;

@property (weak, nonatomic, readonly) STPCheckoutViewController *checkoutController;
@property (weak, nonatomic) STP_VIEW_CLASS *webView;
@property (nonatomic) id<STPCheckoutWebViewAdapter> adapter;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) UIView *headerBackground;
@property (nonatomic) STPCheckoutOptions *options;
@property (nonatomic) NSURL *logoURL;
@property (nonatomic) NSURL *url;
@property (nonatomic, weak) id<STPCheckoutViewControllerDelegate> delegate;

@end

@interface STPCheckoutViewController ()
@property (nonatomic, weak) STPCheckoutWebViewController *webViewController;
@property (nonatomic) UIStatusBarStyle previousStyle;
@end

@implementation STPCheckoutViewController

- (instancetype)initWithOptions:(STPCheckoutOptions *)options {
    STPCheckoutWebViewController *webViewController = [[STPCheckoutWebViewController alloc] initWithCheckoutViewController:self];
    webViewController.options = options;
    self = [super initWithRootViewController:webViewController];
    if (self) {
        _webViewController = webViewController;
        _previousStyle = [[UIApplication sharedApplication] statusBarStyle];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    NSCAssert(self.checkoutDelegate, @"You must provide a delegate to STPCheckoutViewController before showing it.");
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:self.previousStyle animated:YES];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.webViewController;
}

- (void)setCheckoutDelegate:(id<STPCheckoutViewControllerDelegate>)delegate {
    self.webViewController.delegate = delegate;
}

- (id<STPCheckoutViewControllerDelegate>)checkoutDelegate {
    return self.webViewController.delegate;
}

- (STPCheckoutOptions *)options {
    return self.webViewController.options;
}

@end

@implementation STPCheckoutWebViewController

- (instancetype)initWithCheckoutViewController:(STPCheckoutViewController *)checkoutViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelItem;
        _checkoutController = checkoutViewController;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"window.navigator.userAgent"];
            if ([userAgent rangeOfString:checkoutUserAgent].location == NSNotFound) {
                userAgent = [NSString stringWithFormat:@"%@ %@/%@", userAgent, checkoutUserAgent, STPLibraryVersionNumber];
                NSDictionary *defaults = @{ @"UserAgent": userAgent };
                [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
            }
        });
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *fullURLString = [NSString stringWithFormat:@"%@://%@", STPCheckoutURLProtocolRequestScheme, checkoutURL];
    self.url = [NSURL URLWithString:fullURLString];

    if (self.options.logoImage && !self.options.logoURL) {
        NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
        BOOL success = [UIImagePNGRepresentation(self.options.logoImage) writeToURL:url options:0 error:nil];
        if (success) {
            self.logoURL = self.options.logoURL = url;
        }
    }

    self.adapter = [[STPCheckoutUIWebViewAdapter alloc] init];
    self.adapter.delegate = self;
    UIView *webView = self.adapter.webView;
    [self.view addSubview:webView];

    webView.backgroundColor = [UIColor whiteColor];
    if (self.options.logoColor && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.view.backgroundColor = self.options.logoColor;
        webView.backgroundColor = self.options.logoColor;
        webView.opaque = NO;
    }

    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];

    [self.adapter loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView = webView;

    UIView *headerBackground = [[UIView alloc] initWithFrame:self.view.bounds];
    self.headerBackground = headerBackground;
    [self.webView insertSubview:headerBackground atIndex:0];
    headerBackground.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[headerBackground]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(headerBackground)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerBackground
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:0]];
    CGFloat bottomMargin = -150;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        bottomMargin = 0;
    }
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerBackground
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:bottomMargin]];

    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && self.options.logoColor &&
        ![STPColorUtils colorIsLight:self.options.logoColor]) {
        style = UIActivityIndicatorViewStyleWhiteLarge;
    }
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];
}

- (void)cancel:(__unused id)sender {
    [self.delegate checkoutControllerDidCancel:self.checkoutController];
    [self cleanup];
}

- (void)cleanup {
    [self.adapter cleanup];
    if (self.logoURL) {
        [[NSFileManager defaultManager] removeItemAtURL:self.logoURL error:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.options.logoColor && self.checkoutController.navigationBarHidden) {
        FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
        return [STPColorUtils colorIsLight:self.options.logoColor] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
}

- (void)setLogoColor:(STP_COLOR_CLASS *)color {
    self.options.logoColor = color;
    self.headerBackground.backgroundColor = color;
    if ([self.checkoutController respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
        [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle] animated:YES];
        [self.checkoutController setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - UIWebViewDelegate
#pragma mark - STPCheckoutAdapterDelegate

- (void)checkoutAdapterDidStartLoad:(id<STPCheckoutWebViewAdapter>)adapter {
    NSString *optionsJavaScript = [NSString stringWithFormat:@"window.%@ = %@;", checkoutOptionsGlobal, [self.options stringifiedJSONRepresentation]];
    [adapter evaluateJavaScript:optionsJavaScript];
    [self.activityIndicator startAnimating];
}

- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didTriggerEvent:(NSString *)event withPayload:(NSDictionary *)payload {
    if ([event isEqualToString:@"CheckoutDidOpen"]) {
        if (payload != nil && payload[@"logoColor"]) {
            [self setLogoColor:[STPColorUtils colorForHexCode:payload[@"logoColor"]]];
        }
    } else if ([event isEqualToString:@"CheckoutDidTokenize"]) {
        STPToken *token = nil;
        if (payload != nil && payload[@"token"] != nil) {
            token = [[STPToken alloc] initWithAttributeDictionary:payload[@"token"]];
        }
        [self.delegate checkoutController:self.checkoutController
                           didCreateToken:token
                               completion:^(STPBackendChargeResult status, NSError *error) {
                                   if (status == STPBackendChargeResultSuccess) {
                                       [adapter evaluateJavaScript:payload[@"success"]];
                                   } else {
                                       NSString *failure = payload[@"failure"];
                                       NSString *script = [NSString stringWithFormat:failure, error.localizedDescription];
                                       [adapter evaluateJavaScript:script];
                                   }
                               }];
    } else if ([event isEqualToString:@"CheckoutDidFinish"]) {
        [self.delegate checkoutControllerDidFinish:self.checkoutController];
        [self cleanup];
    } else if ([event isEqualToString:@"CheckoutDidCancel"]) {
        [self.delegate checkoutControllerDidCancel:self.checkoutController];
        [self cleanup];
    } else if ([event isEqualToString:@"CheckoutDidError"]) {
        NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPCheckoutError userInfo:payload];
        [self.delegate checkoutController:self.checkoutController didFailWithError:error];
        [self cleanup];
    }
}

- (void)checkoutAdapterDidFinishLoad:(__unused id<STPCheckoutWebViewAdapter>)adapter {
    [UIView animateWithDuration:0.1
        animations:^{
            self.activityIndicator.alpha = 0;
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
        completion:^(__unused BOOL finished) { [self.activityIndicator stopAnimating]; }];
}

- (void)checkoutAdapter:(__unused id<STPCheckoutWebViewAdapter>)adapter didError:(__unused NSError *)error {
    [self.activityIndicator stopAnimating];
    [self.delegate checkoutController:self.checkoutController didFailWithError:error];
    [self cleanup];
}

@end

@implementation STPCheckoutUIWebViewAdapter

@synthesize delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _webView.delegate = self;
        _webView.keyboardDisplayRequiresUserAction = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ [NSURLProtocol registerClass:[STPCheckoutURLProtocol class]]; });
    }
    return self;
}

- (void)dealloc {
    _webView.delegate = nil;
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.webView loadRequest:request];
}

- (void)evaluateJavaScript:(NSString *)js {
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)cleanup {
    if ([self.webView isLoading]) {
        [self.webView stopLoading];
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(__unused UIWebView *)webView {
    [self.delegate checkoutAdapterDidStartLoad:self];
}

- (BOOL)webView:(__unused UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    switch (navigationType) {
    case UIWebViewNavigationTypeLinkClicked: {
        if ([url.host isEqualToString:checkoutHost]) {
            if ([url.path rangeOfString:checkoutRedirectPrefix].location == 0) {
                [[UIApplication sharedApplication] openURL:url];
                return NO;
            }
            return YES;
        }
        return NO;
    }
    case UIWebViewNavigationTypeOther: {
        if ([url.scheme isEqualToString:checkoutRPCScheme]) {
            NSString *event = url.host;
            NSString *path = [url.path componentsSeparatedByString:@"/"][1];
            NSDictionary *payload = nil;
            if (path != nil) {
                payload = [NSJSONSerialization JSONObjectWithData:[path dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            }
            [self.delegate checkoutAdapter:self didTriggerEvent:event withPayload:payload];
            return NO;
        }
        return YES;
    }
    default:
        // add tracking
        return NO;
    }
}

- (void)webViewDidFinishLoad:(__unused UIWebView *)webView {
    [self.delegate checkoutAdapterDidFinishLoad:self];
}

- (void)webView:(__unused UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.delegate checkoutAdapter:self didError:error];
}

@end

#else // OSX

#import <WebKit/WebKit.h>

@interface STPCheckoutOSXWebViewAdapter : NSObject<STPCheckoutWebViewAdapter>
@property (nonatomic) WebView *webView;
@end

@interface STPCheckoutViewController () <STPCheckoutDelegate>
@property (nonatomic) STPCheckoutOSXWebViewAdapter *adapter;
@end

@implementation STPCheckoutViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithOptions:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithOptions:nil];
}

- (instancetype)initWithOptions:(STPCheckoutOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _options = options;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ [NSURLProtocol registerClass:[STPCheckoutURLProtocol class]]; });
    }
    return self;
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self preload];
    NSView *webView = self.adapter.webView;
    [self.view addSubview:webView];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];
}

- (void)viewDidAppear {
    [super viewDidAppear];
}

- (void)preload {
    if (!self.adapter) {
        self.adapter = [STPCheckoutOSXWebViewAdapter new];
        self.adapter.delegate = self;
        NSString *fullURLString = [NSString stringWithFormat:@"%@://%@", STPCheckoutURLProtocolRequestScheme, checkoutURL];
        NSURL *url = [NSURL URLWithString:fullURLString];
        [self.adapter loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

#pragma mark - STPCheckoutAdapterDelegate

- (void)checkoutAdapterDidStartLoad:(id<STPCheckoutWebViewAdapter>)adapter {
    NSString *optionsJavaScript = [NSString stringWithFormat:@"window.%@ = %@;", checkoutOptionsGlobal, [self.options stringifiedJSONRepresentation]];
    [adapter evaluateJavaScript:optionsJavaScript];
}

- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didTriggerEvent:(NSString *)event withPayload:(NSDictionary *)payload {
    if ([event isEqualToString:@"CheckoutDidOpen"]) {
        // no-op for now
    } else if ([event isEqualToString:@"CheckoutDidTokenize"]) {
        STPToken *token = nil;
        if (payload != nil && payload[@"token"] != nil) {
            token = [[STPToken alloc] initWithAttributeDictionary:payload[@"token"]];
        }
        [self.checkoutDelegate checkoutController:self
                                   didCreateToken:token
                                       completion:^(STPBackendChargeResult status, NSError *error) {
                                           if (status == STPBackendChargeResultSuccess) {
                                               [adapter evaluateJavaScript:payload[@"success"]];
                                           } else {
                                               NSString *failure = payload[@"failure"];
                                               NSString *script = [NSString stringWithFormat:failure, error.localizedDescription];
                                               [adapter evaluateJavaScript:script];
                                           }
                                       }];
    } else if ([event isEqualToString:@"CheckoutDidFinish"]) {
        [self.checkoutDelegate checkoutControllerDidFinish:self];
    } else if ([event isEqualToString:@"CheckoutDidCancel"]) {
        [self.checkoutDelegate checkoutControllerDidCancel:self];
    } else if ([event isEqualToString:@"CheckoutDidError"]) {
        NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPCheckoutError userInfo:payload];
        [self.checkoutDelegate checkoutController:self didFailWithError:error];
    }
}

- (void)checkoutAdapterDidFinishLoad:(__unused id<STPCheckoutWebViewAdapter>)adapter {
}

- (void)checkoutAdapter:(__unused id<STPCheckoutWebViewAdapter>)adapter didError:(__unused NSError *)error {
    [self.checkoutDelegate checkoutController:self didFailWithError:error];
}

@end

@implementation STPCheckoutOSXWebViewAdapter

@synthesize delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        _webView = [[WebView alloc] initWithFrame:CGRectZero];
        _webView.drawsBackground = NO;
        _webView.frameLoadDelegate = self;
        _webView.policyDelegate = self;
        _webView.resourceLoadDelegate = self;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ [NSURLProtocol registerClass:[STPCheckoutURLProtocol class]]; });
    }
    return self;
}

- (void)dealloc {
    _webView.frameLoadDelegate = nil;
    _webView.policyDelegate = nil;
    _webView.resourceLoadDelegate = nil;
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.webView.mainFrame loadRequest:request];
}

- (void)evaluateJavaScript:(NSString *)js {
    [self.webView.windowScriptObject evaluateWebScript:js];
}

- (void)cleanup {
    if ([self.webView isLoading]) {
        [self.webView stopLoading:nil];
    }
}

#pragma mark - ResourceLoadDelegate
- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource {
    return request;
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource {
    return request.URL;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
    if ([identifier isEqual:dataSource.initialRequest.URL]) {
        [self.delegate checkoutAdapter:self didError:error];
    }
}

#pragma mark - WebPolicyDelegate
- (void)webView:(WebView *)webView
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                            request:(NSURLRequest *)request
                              frame:(WebFrame *)frame
                   decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSURL *url = request.URL;
    if ([url.scheme.lowercaseString isEqualToString:STPCheckoutURLProtocolRequestScheme.lowercaseString]) {
        [listener use];
        return;
    }
    WebNavigationType navigationType = [actionInformation[WebActionNavigationTypeKey] integerValue];
    switch (navigationType) {
    case WebNavigationTypeLinkClicked: {
        if ([url.host isEqualToString:checkoutHost]) {
            if ([url.path rangeOfString:checkoutRedirectPrefix].location == 0) {
                [[NSWorkspace sharedWorkspace] openURL:url];
                [listener ignore];
                return;
            }
            [listener use];
            return;
        }
        [listener ignore];
        break;
    }
    case WebNavigationTypeOther: {
        if ([url.scheme isEqualToString:checkoutRPCScheme]) {
            NSString *event = url.host;
            NSString *path = [url.path componentsSeparatedByString:@"/"][1];
            NSDictionary *payload = nil;
            if (path != nil) {
                payload = [NSJSONSerialization JSONObjectWithData:[path dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            }
            [self.delegate checkoutAdapter:self didTriggerEvent:event withPayload:payload];
            [listener ignore];
            return;
        }
        [listener use];
        break;
    }
    default:
        // add tracking
        [listener ignore];
        break;
    }
}

#pragma mark - WebFrameLoadDelegate
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    [self.delegate checkoutAdapterDidStartLoad:self];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    [self.delegate checkoutAdapter:self didError:error];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    [self.delegate checkoutAdapterDidFinishLoad:self];
}

@end

#endif

#pragma mark - STPCheckoutURLProtocol

/**
 *  This URL protocol treats any non-20x or 30x response from checkout as an error (unlike the default UIWebView behavior, which e.g. displays a 404 page).
 */
@implementation STPCheckoutURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme.lowercaseString isEqualToString:STPCheckoutURLProtocolRequestScheme.lowercaseString];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    NSString *oldURLString = [[newRequest.URL absoluteString] lowercaseString];
    //#warning todo: https
    newRequest.URL =
        [NSURL URLWithString:[oldURLString stringByReplacingOccurrencesOfString:STPCheckoutURLProtocolRequestScheme.lowercaseString withString:@"http"]];
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // 30x redirects are automatically followed and will not reach here,
        // so we only need to check for successful 20x status codes.
        if (httpResponse.statusCode / 100 != 2 && httpResponse.statusCode != 301) {
            NSError *error = [[NSError alloc] initWithDomain:StripeDomain
                                                        code:STPConnectionError
                                                    userInfo:@{
                                                        NSLocalizedDescriptionKey: STPUnexpectedError,
                                                        STPErrorMessageKey: @"Stripe Checkout couldn't open. Please check your internet connection and try "
                                                        @"again. If the problem persists, please contact support@stripe.com."
                                                    }];
            [self.client URLProtocol:self didFailWithError:error];
            [connection cancel];
            self.connection = nil;
            return;
        }
    }
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(__unused NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(__unused NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(__unused NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
