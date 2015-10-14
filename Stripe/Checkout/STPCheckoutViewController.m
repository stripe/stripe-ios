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
#import "STPStrictURLProtocol.h"
#import "STPCheckoutWebViewAdapter.h"
#import "STPCheckoutDelegate.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

#if TARGET_OS_IPHONE
#pragma mark - iOS

#import "STPIOSCheckoutWebViewAdapter.h"
#import "STPCheckoutInternalUIWebViewController.h"

@interface STPCheckoutViewController ()
@property (nonatomic, weak) STPCheckoutInternalUIWebViewController *webViewController;
@property (nonatomic) UIStatusBarStyle previousStyle;
@end

@implementation STPCheckoutViewController

- (instancetype)initWithOptions:(STPCheckoutOptions *)options {
    STPCheckoutInternalUIWebViewController *webViewController = [[STPCheckoutInternalUIWebViewController alloc] initWithCheckoutViewController:self];
    webViewController.options = options;
    self = [super initWithRootViewController:webViewController];
    if (self) {
        self.navigationBar.translucent = NO;
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

#else // OSX
#pragma mark - OSX

#import "STPOSXCheckoutWebViewAdapter.h"

@interface STPCheckoutViewController () <STPCheckoutDelegate>
@property (nonatomic) STPOSXCheckoutWebViewAdapter *adapter;
@property (nonatomic) BOOL backendChargeSuccessful;
@property (nonatomic) NSError *backendChargeError;
@end

@implementation STPCheckoutViewController

- (instancetype)initWithNibName:(__unused NSString *)nibNameOrNil bundle:(__unused NSBundle *)nibBundleOrNil {
    return [self initWithOptions:[[STPCheckoutOptions alloc] init]];
}

- (instancetype)initWithCoder:(__unused NSCoder *)coder {
    return [self initWithOptions:[[STPCheckoutOptions alloc] init]];
}

- (instancetype)initWithOptions:(STPCheckoutOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _options = options;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ [NSURLProtocol registerClass:[STPStrictURLProtocol class]]; });
    }
    return self;
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:CGRectZero];
    self.view = view;
    if (!self.adapter) {
        self.adapter = [STPOSXCheckoutWebViewAdapter new];
        self.adapter.delegate = self;
        NSURL *url = [NSURL URLWithString:checkoutURLString];
        [self.adapter loadRequest:[NSURLRequest requestWithURL:url]];
    }
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

#pragma mark STPCheckoutDelegate

- (void)checkoutAdapterDidStartLoad:(id<STPCheckoutWebViewAdapter>)adapter {
    NSString *optionsJavaScript = [NSString stringWithFormat:@"window.%@ = %@;", checkoutOptionsGlobal, [self.options stringifiedJSONRepresentation]];
    [adapter evaluateJavaScript:optionsJavaScript];
}

- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didTriggerEvent:(NSString *)event withPayload:(NSDictionary *)payload {
    if ([event isEqualToString:STPCheckoutEventOpen]) {
        // no-op for now
    } else if ([event isEqualToString:STPCheckoutEventTokenize]) {
        STPToken *token = nil;
        if (payload != nil && payload[@"token"] != nil) {
            token = [STPToken decodedObjectFromAPIResponse:payload[@"token"]];
        }
        [self.checkoutDelegate checkoutController:self
                                   didCreateToken:token
                                       completion:^(STPBackendChargeResult status, NSError *error) {
                                           self.backendChargeSuccessful = (status == STPBackendChargeResultSuccess);
                                           self.backendChargeError = error;
                                           if (status == STPBackendChargeResultSuccess) {
                                               [adapter evaluateJavaScript:payload[@"success"]];
                                           } else {
                                               NSString *encodedError = @"";
                                               if (error.localizedDescription) {
                                                   encodedError = [[NSString alloc]
                                                       initWithData:[NSJSONSerialization dataWithJSONObject:@[error.localizedDescription] options:0 error:nil]
                                                           encoding:NSUTF8StringEncoding];
                                                   encodedError = [encodedError substringWithRange:NSMakeRange(2, encodedError.length - 4)];
                                               }
                                               NSString *failure = payload[@"failure"];
                                               NSString *script = [NSString stringWithFormat:failure, encodedError];
                                               [adapter evaluateJavaScript:script];
                                           }
                                       }];
    } else if ([event isEqualToString:STPCheckoutEventFinish]) {
        if (self.backendChargeSuccessful) {
            [self.checkoutDelegate checkoutController:self didFinishWithStatus:STPPaymentStatusSuccess error:nil];
        } else {
            [self.checkoutDelegate checkoutController:self didFinishWithStatus:STPPaymentStatusError error:self.backendChargeError];
        }
    } else if ([event isEqualToString:STPCheckoutEventCancel]) {
        [self.checkoutDelegate checkoutController:self didFinishWithStatus:STPPaymentStatusUserCancelled error:nil];
    } else if ([event isEqualToString:STPCheckoutEventError]) {
        NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPCheckoutError userInfo:payload];
        [self.checkoutDelegate checkoutController:self didFinishWithStatus:STPPaymentStatusError error:error];
    }
}

- (void)checkoutAdapterDidFinishLoad:(__unused id<STPCheckoutWebViewAdapter>)adapter {
}

- (void)checkoutAdapter:(__unused id<STPCheckoutWebViewAdapter>)adapter didError:(NSError *)error {
    [self.checkoutDelegate checkoutController:self didFinishWithStatus:STPPaymentStatusError error:error];
}

@end

#endif

#pragma clang diagnostic pop
