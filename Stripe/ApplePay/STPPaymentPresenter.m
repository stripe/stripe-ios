//
//  STPPaymentPresenter.m
//  Stripe
//
//  Created by Jack Flintermann on 11/25/14.
//

#import "STPPaymentPresenter.h"
#import <PassKit/PassKit.h>
#import "StripeError.h"
#import <objc/runtime.h>
#import "STPCheckoutViewController.h"
#import "STPAPIClient.h"
#import "STPAPIClient+ApplePay.h"
#import "Stripe+ApplePay.h"

static const NSString *STPPaymentPresenterAssociatedObjectKey = @"STPPaymentPresenterAssociatedObjectKey";

@interface STPCheckoutOptions (PaymentRequestAdditions)
@property (nonatomic, readonly) PKPaymentRequest *paymentRequest;
@end

@interface STPPaymentPresenter () <STPCheckoutViewControllerDelegate, PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, weak) id<STPPaymentPresenterDelegate> delegate;
@property (nonatomic, copy) STPCheckoutOptions *checkoutOptions;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (weak, nonatomic) UIViewController *presentedViewController;
@property (nonatomic) BOOL hasAuthorizedPayment;
@property (nonatomic) NSError *error;
@property (nonatomic) STPAPIClient *apiClient;
@end

@implementation STPPaymentPresenter

- (instancetype)initWithCheckoutOptions:(STPCheckoutOptions *)checkoutOptions delegate:(id<STPPaymentPresenterDelegate>)delegate {
    NSCAssert(checkoutOptions && delegate, @"You cannot pass nil values for checkoutOptions or delegate when creating an STPPaymentPresenter.");
    self = [super init];
    if (self) {
        _delegate = delegate;
        _checkoutOptions = checkoutOptions;
        _apiClient = [[STPAPIClient alloc] initWithPublishableKey:_checkoutOptions.publishableKey];
    }
    return self;
}

- (void)requestPaymentFromPresentingViewController:(UIViewController *)presentingViewController {
    if (presentingViewController.presentedViewController && presentingViewController.presentedViewController == self.presentedViewController) {
        NSLog(@"Error: called requestPaymentFromPresentingViewController: while already presenting a payment view controller.");
        return;
    }
    NSCAssert(presentingViewController, @"You cannot call requestPaymentFromPresentingViewController: with a nil argument.");
    self.presentingViewController = presentingViewController;

    // we really don't want to get dealloc'ed in case the caller doesn't remember to retain this object.
    objc_setAssociatedObject(self.presentingViewController, &STPPaymentPresenterAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN);
    if ([PKPaymentRequest class]) {
        PKPaymentRequest *paymentRequest = self.checkoutOptions.paymentRequest;
        if (paymentRequest) {
            if ([self.delegate respondsToSelector:@selector(paymentPresenter:didPreparePaymentRequest:)]) {
                paymentRequest = [self.delegate paymentPresenter:self didPreparePaymentRequest:paymentRequest];
            }
            if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
                if ([self.class isSimulatorBuild]) {
                    NSLog(@"Apple Pay is properly configured but can't run in the simulator. Falling back to Stripe Checkout.");
                } else {
                    PKPaymentAuthorizationViewController *paymentViewController =
                        [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
                    if (paymentViewController) {
                        paymentViewController.delegate = self;
                        [self.presentingViewController presentViewController:paymentViewController animated:YES completion:nil];
                        self.presentedViewController = paymentViewController;
                        return;
                    } else {
                        NSLog(@"Warning: -[PKPaymentAuthorizationViewController initWithPaymentRequest:] returned nil. Something is wrong with your "
                              @"PKPaymentRequest.");
                    }
                }
            }
        }
    }
    STPCheckoutViewController *checkoutViewController = [[STPCheckoutViewController alloc] initWithOptions:self.checkoutOptions];
    checkoutViewController.checkoutDelegate = self;
    self.presentedViewController = checkoutViewController;
    [self.presentingViewController presentViewController:checkoutViewController animated:YES completion:nil];
}

- (void)finishWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    [self.delegate paymentPresenter:self didFinishWithStatus:status error:error];
    objc_setAssociatedObject(self.presentingViewController, &STPPaymentPresenterAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN);
}

+ (BOOL)isSimulatorBuild {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

#pragma mark - STPCheckoutViewControllerDelegate

- (void)checkoutController:(__unused STPCheckoutViewController *)controller didFinishWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    [self finishWithStatus:status error:error];
}

- (void)checkoutController:(__unused STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPTokenSubmissionHandler)checkoutCompletion {
    STPTokenSubmissionHandler completion = ^(STPBackendChargeResult status, NSError *backendError) {
        self.error = backendError;
        self.hasAuthorizedPayment = (status == STPBackendChargeResultSuccess);
        checkoutCompletion(status, backendError);
    };
    [self.delegate paymentPresenter:self didCreateStripeToken:token completion:completion];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

typedef void (^STPPaymentAuthorizationStatusBlock)(PKPaymentAuthorizationStatus status);
- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(STPPaymentAuthorizationStatusBlock)pkCompletion {
    [self.apiClient createTokenWithPayment:payment
                                completion:^(STPToken *token, NSError *error) {
                                    if (error) {
                                        [self finishWithStatus:STPPaymentStatusError error:error];
                                        return;
                                    }
                                    STPTokenSubmissionHandler completion = ^(STPBackendChargeResult status, NSError *backendError) {
                                        self.error = backendError;
                                        if (status == STPBackendChargeResultSuccess) {
                                            self.hasAuthorizedPayment = YES;
                                            pkCompletion(PKPaymentAuthorizationStatusSuccess);
                                        } else {
                                            pkCompletion(PKPaymentAuthorizationStatusFailure);
                                        }
                                    };
                                    [self.delegate paymentPresenter:self didCreateStripeToken:token completion:completion];
                                }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(__unused PKPaymentAuthorizationViewController *)controller {
    STPPaymentStatus status;
    if (self.error) {
        status = STPPaymentStatusError;
    } else if (self.hasAuthorizedPayment) {
        status = STPPaymentStatusSuccess;
    } else {
        status = STPPaymentStatusUserCancelled;
    }
    [self finishWithStatus:status error:self.error];
}

@end

@implementation STPCheckoutOptions (PaymentRequestAdditions)

- (PKPaymentRequest *)paymentRequest {
    if (!self.appleMerchantId || !self.purchaseAmount || !self.companyName) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.appleMerchantId];
    paymentRequest.currencyCode = self.purchaseCurrency;

    NSMutableArray *paymentSummaryItems = [@[] mutableCopy];
    
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:@(self.purchaseAmount / 100).decimalValue];
    if (self.purchaseDescription) {
        PKPaymentSummaryItem *item = [PKPaymentSummaryItem summaryItemWithLabel:self.purchaseDescription amount:amount];
        [paymentSummaryItems addObject:item];
    }
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:self.companyName amount:amount];
    [paymentSummaryItems addObject:total];
    paymentRequest.paymentSummaryItems = [paymentSummaryItems copy];

    if ([self.requireBillingAddress boolValue]) {
        paymentRequest.requiredBillingAddressFields = PKAddressFieldPostalAddress;
    }

    return paymentRequest;
}

@end
