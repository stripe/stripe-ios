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
#import "FauxPasAnnotations.h"

@interface STPCheckoutWebViewController : UIViewController<UIWebViewDelegate>

- (instancetype)initWithCheckoutViewController:(STPCheckoutViewController *)checkoutViewController;

@property (weak, nonatomic, readonly) STPCheckoutViewController *checkoutController;
@property (weak, nonatomic) UIWebView *webView;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) STPCheckoutOptions *options;
@property (nonatomic) NSURL *logoURL;
@property (nonatomic) NSURL *url;
@property (weak, nonatomic) UIView *headerBackground;
@property (nonatomic, weak) id<STPCheckoutViewControllerDelegate> delegate;

@end

@interface STPCheckoutURLProtocol : NSURLProtocol<NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@end

NSString *const STPCheckoutURLProtocolRequestScheme = @"beginstripecheckout";

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

static NSString *const checkoutOptionsGlobal = @"StripeCheckoutOptions";
static NSString *const checkoutRedirectPrefix = @"/-/";
static NSString *const checkoutRPCScheme = @"stripecheckout";
static NSString *const checkoutUserAgent = @"Stripe";
// static NSString *const checkoutURL = @"checkout.stripe.com/v3/ios";
static NSString *const checkoutURL = @"localhost:5394/v3/ios/index.html";

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
            [NSURLProtocol registerClass:[STPCheckoutURLProtocol class]];
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

    UIWebView *webView = [[UIWebView alloc] init];
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
    webView.keyboardDisplayRequiresUserAction = NO;

    [webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    webView.delegate = self;
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

- (void)cancel:(__unused UIBarButtonItem *)sender {
    [self.delegate checkoutControllerDidCancel:self.checkoutController];
    [self cleanup];
}

- (void)cleanup {
    if ([self.webView isLoading]) {
        [self.webView stopLoading];
    }
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

- (void)setLogoColor:(UIColor *)color {
    self.options.logoColor = color;
    self.headerBackground.backgroundColor = color;
    if ([self.checkoutController respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
        [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle] animated:YES];
        [self.checkoutController setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSString *optionsJavaScript = [NSString stringWithFormat:@"window.%@ = %@;", checkoutOptionsGlobal, [self.options stringifiedJSONRepresentation]];
    [webView stringByEvaluatingJavaScriptFromString:optionsJavaScript];
    [self.activityIndicator startAnimating];
}

- (BOOL)webView:(__unused UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if (navigationType == UIWebViewNavigationTypeLinkClicked && [url.host isEqualToString:self.url.host] &&
        [url.path rangeOfString:checkoutRedirectPrefix].location == 0) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
    if ([url.scheme isEqualToString:checkoutRPCScheme]) {
        NSString *event = url.host;
        NSString *path = [url.path componentsSeparatedByString:@"/"][1];
        NSDictionary *payload = nil;
        if (path != nil) {
            payload = [NSJSONSerialization JSONObjectWithData:[path dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }

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
                                           [webView stringByEvaluatingJavaScriptFromString:payload[@"success"]];
                                       } else {
                                           NSString *failure = payload[@"failure"];
                                           NSString *script = [NSString stringWithFormat:failure, error.localizedDescription];
                                           [webView stringByEvaluatingJavaScriptFromString:script];
                                       }
                                   }];
        } else if ([event isEqualToString:@"CheckoutDidFinish"]) {
            [self.delegate checkoutControllerDidFinish:self.checkoutController];
            [self cleanup];
        } else if ([url.host isEqualToString:@"CheckoutDidCancel"]) {
            [self.delegate checkoutControllerDidCancel:self.checkoutController];
            [self cleanup];
        } else if ([event isEqualToString:@"CheckoutDidError"]) {
            NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPCheckoutError userInfo:payload];
            [self.delegate checkoutController:self.checkoutController didFailWithError:error];
            [self cleanup];
        }
        return NO;
    }
    return navigationType == UIWebViewNavigationTypeOther;
}

- (void)webViewDidFinishLoad:(__unused UIWebView *)webView {
    [UIView animateWithDuration:0.1
        animations:^{
            self.activityIndicator.alpha = 0;
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
        completion:^(__unused BOOL finished) { [self.activityIndicator stopAnimating]; }];
}

- (void)webView:(__unused UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityIndicator stopAnimating];
    [self.delegate checkoutController:self.checkoutController didFailWithError:error];
    [self cleanup];
}

@end

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
