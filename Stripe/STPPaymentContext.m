//
//  STPPaymentContext.m
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import <objc/runtime.h>

#import "PKPaymentAuthorizationViewController+Stripe_Blocks.h"
#import "STPAddCardViewController+Private.h"
#import "STPCustomer+Stripe_PaymentMethods.h"
#import "STPDispatchFunctions.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "STPPaymentContextAmountModel.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodTuple.h"
#import "STPPaymentMethodType+Private.h"
#import "STPPromise.h"
#import "STPShippingMethodsViewController.h"
#import "STPSourceProtocol.h"
#import "STPWeakStrongMacros.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)


/**
 The current state of the payment context

 - STPPaymentContextStateNone: No view controllers are currently being shown. The payment may or may not have already been completed
 - STPPaymentContextStateShowingRequestedViewController: The view controller that you requested the context show is being shown (via the push or present payment methods or shipping view controller methods)
 - STPPaymentContextStateRequestingPayment: The payment context is in the middle of requesting payment. It may be showing some other UI or view controller if more information is necessary to complete the payment.
 */
typedef NS_ENUM(NSUInteger, STPPaymentContextState) {
    STPPaymentContextStateNone,
    STPPaymentContextStateShowingRequestedViewController,
    STPPaymentContextStateRequestingPayment,
};

@interface STPPaymentContext()<STPPaymentMethodsViewControllerDelegate, STPShippingAddressViewControllerDelegate>

@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)STPTheme *theme;
@property(nonatomic)id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPPromise<STPPaymentMethodTuple *> *loadingPromise;

// these wrap hostViewController's promises because the hostVC is nil at init-time
@property(nonatomic)STPVoidPromise *willAppearPromise;
@property(nonatomic)STPVoidPromise *didAppearPromise;

@property(nonatomic, weak)STPPaymentMethodsViewController *paymentMethodsViewController;
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)STPAddress *shippingAddress;
@property(nonatomic)PKShippingMethod *selectedShippingMethod;
@property(nonatomic)NSArray<PKShippingMethod *> *shippingMethods;

@property(nonatomic, assign) STPPaymentContextState state;

@property(nonatomic)STPPaymentContextAmountModel *paymentAmountModel;
@property(nonatomic)STPPaymentMethodTuple *paymentMethodTuple;


@end

@implementation STPPaymentContext

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter {
    return [self initWithAPIAdapter:apiAdapter
                      configuration:[STPPaymentConfiguration sharedConfiguration]
                              theme:[STPTheme defaultTheme]];
}

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                     configuration:(STPPaymentConfiguration *)configuration
                             theme:(STPTheme *)theme {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _apiAdapter = apiAdapter;
        _theme = theme;
        _willAppearPromise = [STPVoidPromise new];
        _didAppearPromise = [STPVoidPromise new];
        _apiClient = [[STPAPIClient alloc] initWithPublishableKey:configuration.publishableKey];
        _paymentCurrency = @"USD";
        _paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithAmount:0];
        _modalPresentationStyle = UIModalPresentationFullScreen;
        _state = STPPaymentContextStateNone;
        [self retryLoading];
    }
    return self;
}

- (void)retryLoading {
    if (self.loadingPromise && self.loadingPromise.value) {
        return;
    }
    WEAK(self);
    self.loadingPromise = [[[STPPromise<STPPaymentMethodTuple *> new] onSuccess:^(STPPaymentMethodTuple *tuple) {
        STRONG(self);
        self.paymentMethodTuple = tuple;
    }] onFailure:^(NSError * _Nonnull error) {
        STRONG(self);
        if (self.hostViewController) {
            [self.didAppearPromise onSuccess:^(__unused id value) {
                if (self.paymentMethodsViewController) {
                    [self appropriatelyDismissPaymentMethodsViewController:self.paymentMethodsViewController completion:^{
                        [self.delegate paymentContext:self didFailToLoadWithError:error];
                    }];
                } else {
                    [self.delegate paymentContext:self didFailToLoadWithError:error];
                }
            }];
        }
    }];
    [self.apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable error) {
        stpDispatchToMainThreadIfNecessary(^{
            STRONG(self);
            if (!self) {
                return;
            }
            if (error) {
                [self.loadingPromise fail:error];
                return;
            }

            [self.loadingPromise succeed:[customer stp_paymentMethodTupleWithConfiguration:self.configuration]];
        });
    }];
}

- (BOOL)loading {
    return !self.loadingPromise.completed;
}

- (void)setHostViewController:(UIViewController *)hostViewController {
    NSCAssert(_hostViewController == nil, @"You cannot change the hostViewController on an STPPaymentContext after it's already been set.");
    _hostViewController = hostViewController;
    [self artificiallyRetain:hostViewController];
    [self.willAppearPromise voidCompleteWith:hostViewController.stp_willAppearPromise];
    [self.didAppearPromise voidCompleteWith:hostViewController.stp_didAppearPromise];
}

- (void)setDelegate:(id<STPPaymentContextDelegate>)delegate {
    _delegate = delegate;
    WEAK(self);
    [self.willAppearPromise voidOnSuccess:^{
        STRONG(self);
        if (self.delegate == delegate) {
            [delegate paymentContextDidChange:self];
        }
    }];
}

- (STPPromise<STPPaymentMethodTuple *> *)currentValuePromise {
    WEAK(self);
    return (STPPromise<STPPaymentMethodTuple *> *)[self.loadingPromise map:^id _Nonnull(__unused STPPaymentMethodTuple *value) {
        STRONG(self);
        return self.paymentMethodTuple;
    }];
}

- (void)setPaymentMethodTuple:(STPPaymentMethodTuple *)paymentMethodTuple {
    if (![_paymentMethodTuple isEqual:paymentMethodTuple]) {
        _paymentMethodTuple = paymentMethodTuple;
        stpDispatchToMainThreadIfNecessary(^{
            [self.delegate paymentContextDidChange:self];
        });
    }
}

- (void)setSelectedPaymentMethod:(id<STPPaymentMethod>)selectedPaymentMethod {
    if ([selectedPaymentMethod isEqual:self.selectedPaymentMethod]) {
        return;
    }
    else {
        NSArray *savedPayments = self.paymentMethodTuple.savedPaymentMethods;
        NSArray *availablePaymentTypes = self.paymentMethodTuple.availablePaymentTypes;

        if (selectedPaymentMethod
            && ![savedPayments containsObject:selectedPaymentMethod]
            && ![availablePaymentTypes containsObject:selectedPaymentMethod]) {

            if ([selectedPaymentMethod isKindOfClass:[STPPaymentMethodType class]]) {
                availablePaymentTypes = [availablePaymentTypes arrayByAddingObject:selectedPaymentMethod];

            }
            else {
                savedPayments = [STPCustomer stp_sortedPaymentMethodsFromArray:[savedPayments arrayByAddingObject:selectedPaymentMethod]
                                                                     sortOrder:self.configuration.availablePaymentMethodTypesSet];
            }
        }

        self.paymentMethodTuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:savedPayments
                                                                       availablePaymentTypes:availablePaymentTypes
                                                                       selectedPaymentMethod:selectedPaymentMethod];
    }
}

- (id<STPPaymentMethod>)selectedPaymentMethod {
    return self.paymentMethodTuple.selectedPaymentMethod;
}

- (NSArray<id<STPPaymentMethod>> *)paymentMethods {
    return self.paymentMethodTuple.allPaymentMethods.allObjects;
}

- (void)setPaymentAmount:(NSInteger)paymentAmount {
    self.paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithAmount:paymentAmount];
}

- (NSInteger)paymentAmount {
    return [self.paymentAmountModel paymentAmountWithCurrency:self.paymentCurrency
                                               shippingMethod:self.selectedShippingMethod];
}

- (void)setPaymentSummaryItems:(NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)
    self.paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithPaymentSummaryItems:paymentSummaryItems];
}

- (NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)
    return [self.paymentAmountModel paymentSummaryItemsWithCurrency:self.paymentCurrency
                                                        companyName:self.configuration.companyName
                                                     shippingMethod:self.selectedShippingMethod];
}

- (void)setShippingMethods:(NSArray<PKShippingMethod *> *)shippingMethods {
    _shippingMethods = shippingMethods;
    if (shippingMethods != nil && self.selectedShippingMethod != nil) {
        if ([shippingMethods count] == 0) {
            self.selectedShippingMethod = nil;
        }
        else if ([shippingMethods indexOfObject:self.selectedShippingMethod] == NSNotFound) {
            self.selectedShippingMethod = [shippingMethods firstObject];
        }
    }
}

#pragma mark - Payment Methods

- (void)presentPaymentMethodsViewController {
    [self presentPaymentMethodsViewControllerWithNewState:STPPaymentContextStateShowingRequestedViewController];
}

- (void)presentPaymentMethodsViewControllerWithNewState:(STPPaymentContextState)state {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushPaymentMethodsViewController on it. Next time, set the hostViewController property first!");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        if (self.state == STPPaymentContextStateNone) {
            self.state = state;
            STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:self];
            self.paymentMethodsViewController = paymentMethodsViewController;
            paymentMethodsViewController.prefilledInformation = self.prefilledInformation;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsViewController];
            navigationController.navigationBar.stp_theme = self.theme;
            navigationController.modalPresentationStyle = self.modalPresentationStyle;
            [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
        }
    }];
}

- (void)pushPaymentMethodsViewController {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushPaymentMethodsViewController on it. Next time, set the hostViewController property first!");
    UINavigationController *navigationController;
    if ([self.hostViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)self.hostViewController;
    } else {
        navigationController = self.hostViewController.navigationController;
    }
    NSCAssert(self.hostViewController != nil, @"The payment context's hostViewController is not a navigation controller, or is not contained in one. Either make sure it is inside a navigation controller before calling pushPaymentMethodsViewController, or call presentPaymentMethodsViewController instead.");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        if (self.state == STPPaymentContextStateNone) {
            self.state = STPPaymentContextStateShowingRequestedViewController;

            STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:self];
            self.paymentMethodsViewController = paymentMethodsViewController;
            paymentMethodsViewController.prefilledInformation = self.prefilledInformation;
            [navigationController pushViewController:paymentMethodsViewController animated:YES];
        }
    }];
}

- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController
              didSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    self.selectedPaymentMethod = paymentMethod;
}

- (void)paymentMethodsViewControllerDidFinish:(STPPaymentMethodsViewController *)paymentMethodsViewController {
    [self appropriatelyDismissPaymentMethodsViewController:paymentMethodsViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            self.state = STPPaymentContextStateNone;
            [self requestPayment];
        }
        else {
            self.state = STPPaymentContextStateNone;
        }
    }];
}

- (void)paymentMethodsViewControllerDidCancel:(STPPaymentMethodsViewController *)paymentMethodsViewController {
    [self appropriatelyDismissPaymentMethodsViewController:paymentMethodsViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                error:nil];
        }
        else {
            self.state = STPPaymentContextStateNone;
        }
    }];
}

- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController
              didFailToLoadWithError:(__unused NSError *)error {
    // we'll handle this ourselves when the loading promise fails.
}

- (void)appropriatelyDismissPaymentMethodsViewController:(STPPaymentMethodsViewController *)viewController
                                              completion:(STPVoidBlock)completion {
    if ([viewController stp_isAtRootOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [viewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            self.paymentMethodsViewController = nil;
            if (completion) {
                completion();
            }
        }];
    } else {
        // otherwise, we've been pushed onto the stack.
        [viewController.navigationController stp_popToViewController:self.hostViewController animated:YES completion:^{
            self.paymentMethodsViewController = nil;
            if (completion) {
                completion();
            }
        }];
    }
}

#pragma mark - Shipping Info

- (void)presentShippingViewController {
    [self presentShippingViewControllerWithNewState:STPPaymentContextStateShowingRequestedViewController];
}

- (void)presentShippingViewControllerWithNewState:(STPPaymentContextState)state {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling presentShippingViewController on it. Next time, set the hostViewController property first!");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        if (self.state == STPPaymentContextStateNone) {
            self.state = state;

            STPShippingAddressViewController *addressViewController = [[STPShippingAddressViewController alloc] initWithPaymentContext:self];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addressViewController];
            navigationController.navigationBar.stp_theme = self.theme;
            navigationController.modalPresentationStyle = self.modalPresentationStyle;
            [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
        }
    }];
}

- (void)pushShippingViewController {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushShippingViewController on it. Next time, set the hostViewController property first!");
    UINavigationController *navigationController;
    if ([self.hostViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)self.hostViewController;
    } else {
        navigationController = self.hostViewController.navigationController;
    }
    NSCAssert(self.hostViewController != nil, @"The payment context's hostViewController is not a navigation controller, or is not contained in one. Either make sure it is inside a navigation controller before calling pushShippingInfoViewController, or call presentShippingInfoViewController instead.");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        if (self.state == STPPaymentContextStateNone) {
            self.state = STPPaymentContextStateShowingRequestedViewController;

            STPShippingAddressViewController *addressViewController = [[STPShippingAddressViewController alloc] initWithPaymentContext:self];
            [navigationController pushViewController:addressViewController animated:YES];
        }
    }];
}

- (void)shippingAddressViewControllerDidCancel:(STPShippingAddressViewController *)addressViewController {
    [self appropriatelyDismissViewController:addressViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                error:nil];
        }
        else {
            self.state = STPPaymentContextStateNone;
        }
    }];
}

- (void)shippingAddressViewController:(__unused STPShippingAddressViewController *)addressViewController
                      didEnterAddress:(STPAddress *)address
                           completion:(STPShippingMethodsCompletionBlock)completion {
    if ([self.delegate respondsToSelector:@selector(paymentContext:didUpdateShippingAddress:completion:)]) {
        [self.delegate paymentContext:self didUpdateShippingAddress:address completion:^(STPShippingStatus status, NSError *shippingValidationError, NSArray<PKShippingMethod *> * shippingMethods, PKShippingMethod *selectedMethod) {
            self.shippingMethods = shippingMethods;
            if (completion) {
                completion(status, shippingValidationError, shippingMethods, selectedMethod);
            }
        }];
    }
    else {
        if (completion) {
            completion(STPShippingStatusValid, nil, nil, nil);
        }
    }
}

- (void)shippingAddressViewController:(STPShippingAddressViewController *)addressViewController
                 didFinishWithAddress:(STPAddress *)address
                       shippingMethod:(PKShippingMethod *)method {
    self.shippingAddress = address;
    self.selectedShippingMethod = method;
    [self.delegate paymentContextDidChange:self];
    [self appropriatelyDismissViewController:addressViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            self.state = STPPaymentContextStateNone;
            [self requestPayment];
        }
    }];
}

- (void)appropriatelyDismissViewController:(UIViewController *)viewController
                                completion:(STPVoidBlock)completion {
    if ([viewController stp_isAtRootOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [viewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            if (completion) {
                completion();
            }
        }];
    } else {
        // otherwise, we've been pushed onto the stack.
        [viewController.navigationController stp_popToViewController:self.hostViewController animated:YES completion:^{
            if (completion) {
                completion();
            }
        }];
    }
}

#pragma mark - Request Payment

- (void)requestPayment {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    WEAK(self);
    [[[self.didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
        STRONG(self);
        return self.loadingPromise;
    }] onSuccess:^(__unused STPPaymentMethodTuple *tuple) {
        STRONG(self);
        if (!self) {
            return;
        }

        if (self.state != STPPaymentContextStateNone) {
            return;
        }

        if (!self.selectedPaymentMethod) {
            [self presentPaymentMethodsViewControllerWithNewState:STPPaymentContextStateRequestingPayment];
        }
        else if (self.configuration.requiredShippingAddressFields != STPBillingAddressFieldsNone &&
                 !self.shippingAddress)
        {
            [self presentShippingViewControllerWithNewState:STPPaymentContextStateRequestingPayment];
        }
        else if ([self.selectedPaymentMethod isKindOfClass:[STPCard class]]) {
            self.state = STPPaymentContextStateRequestingPayment;
            STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:(STPCard *)self.selectedPaymentMethod];
            [self.delegate paymentContext:self didCreatePaymentResult:result completion:^(NSError * _Nullable error) {
                stpDispatchToMainThreadIfNecessary(^{
                    if (error) {
                        [self didFinishWithStatus:STPPaymentStatusError error:error];
                    } else {
                        [self didFinishWithStatus:STPPaymentStatusSuccess error:nil];
                    }
                });
            }];
        }
        else if ([self.selectedPaymentMethod isKindOfClass:[STPSource class]]) {
            // TODO:
            // Concrete source object, check flow to see if synchronous charge or webhook based
            // If a card source, we need to check if the user wants us to 3DS or not

            self.state = STPPaymentContextStateRequestingPayment;

            STPSource *source = (STPSource *)self.selectedPaymentMethod;

            switch (source.flow) {
                case STPSourceFlowNone: {
                    // TODO: if this is a card, check if 3DS should be used
                    STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:source];
                    [self.delegate paymentContext:self didCreatePaymentResult:result completion:^(NSError * _Nullable error) {
                        stpDispatchToMainThreadIfNecessary(^{
                            if (error) {
                                [self didFinishWithStatus:STPPaymentStatusError error:error];
                            } else {
                                [self didFinishWithStatus:STPPaymentStatusSuccess error:nil];
                            }
                        });
                    }];

                }
                    break;
                case STPSourceFlowRedirect: {

                    STPVoidBlock onRedirectReturn = ^ {
                        if ([self.delegate respondsToSelector:@selector(paymentContextDidReturnFromRedirect:)]) {
                            [self.delegate paymentContextDidReturnFromRedirect:self];
                        }
                    };

                    STPSourceCompletionBlock onRedirectCompletion = ^(STPSource *finishedSource, NSError *error) {
                        stpDispatchToMainThreadIfNecessary(^{
                            if (error) {
                                [self didFinishWithStatus:STPPaymentStatusError error:error];
                            } else {
                                switch (finishedSource.status) {
                                    case STPSourceStatusChargeable:
                                    case STPSourceStatusConsumed:
                                        [self didFinishWithStatus:STPPaymentStatusSuccess
                                                            error:nil];
                                        break;
                                    case STPSourceStatusPending:
                                        [self didFinishWithStatus:STPPaymentStatusPending
                                                            error:nil];
                                        break;
                                    case STPSourceStatusFailed:
                                        /*
                                         Source status failed is a failure because
                                         the user did not do the redirect action and
                                         so is treated as a user cancel
                                         */
                                        [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                                            error:nil];
                                        break;
                                    case STPSourceStatusCanceled:
                                        /*
                                         Source status canceled is a failure because
                                         the merchant did not charge the source quickly enough
                                         and it expired, and so is an error.
                                         */
                                        [self didFinishWithStatus:STPPaymentStatusError
                                                            error:[NSError stp_genericFailedToParseResponseError]];
                                        break;
                                    case STPSourceStatusUnknown:
                                        [self didFinishWithStatus:STPPaymentStatusError
                                                            error:[NSError stp_genericFailedToParseResponseError]];
                                        break;
                                }
                            }
                        });
                    };

                    self.configuration.sourceURLRedirectBlock(self.apiClient,
                                                              source,
                                                              onRedirectReturn,
                                                              onRedirectCompletion);
                }
                    break;
                case STPSourceFlowReceiver:
                case STPSourceFlowCodeVerification:
                case STPSourceFlowUnknown:
                {
                    // We don't support this type
                    [self didFinishWithStatus:STPPaymentStatusError
                                        error:[NSError stp_genericFailedToParseResponseError]];
                }
                    break;
            }
        }
        else if ([self.selectedPaymentMethod isEqual:[STPPaymentMethodType applePay]]) {
            self.state = STPPaymentContextStateRequestingPayment;
            PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
            STPShippingAddressSelectionBlock shippingAddressHandler = ^(STPAddress *shippingAddress, STPShippingAddressValidationBlock completion) {
                // Apple Pay always returns a partial address here, so we won't
                // update self.shippingAddress or self.shippingMethods
                if ([self.delegate respondsToSelector:@selector(paymentContext:didUpdateShippingAddress:completion:)]) {
                    [self.delegate paymentContext:self didUpdateShippingAddress:shippingAddress completion:^(STPShippingStatus status, __unused NSError *shippingValidationError, NSArray<PKShippingMethod *> *shippingMethods, __unused PKShippingMethod *selectedMethod) {
                        completion(status, shippingMethods, self.paymentSummaryItems);
                    }];
                }
                else {
                    completion(STPShippingStatusValid, self.shippingMethods, self.paymentSummaryItems);
                }
            };
            STPShippingMethodSelectionBlock shippingMethodHandler = ^(PKShippingMethod *shippingMethod, STPPaymentSummaryItemCompletionBlock completion) {
                self.selectedShippingMethod = shippingMethod;
                [self.delegate paymentContextDidChange:self];
                completion(self.paymentSummaryItems);
            };
            STPPaymentAuthorizationBlock paymentHandler = ^(PKPayment *payment) {
                self.selectedShippingMethod = payment.shippingMethod;
                self.shippingAddress = [[STPAddress alloc] initWithABRecord:payment.shippingAddress];
                [self.delegate paymentContextDidChange:self];
            };
            STPApplePayTokenHandlerBlock applePayTokenHandler = ^(STPToken *token, STPErrorBlock tokenCompletion) {
                [self.apiAdapter attachSourceToCustomer:token completion:^(NSError *tokenError) {
                    stpDispatchToMainThreadIfNecessary(^{
                        if (tokenError) {
                            tokenCompletion(tokenError);
                        } else {
                            STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:token.card];
                            [self.delegate paymentContext:self didCreatePaymentResult:result completion:^(NSError * error) {
                                // for Apple Pay, the didFinishWithStatus callback is fired later when Apple Pay VC finishes
                                if (error) {
                                    tokenCompletion(error);
                                } else {
                                    tokenCompletion(nil);
                                }
                            }];
                        }
                    });
                }];
            };
            PKPaymentAuthorizationViewController *paymentAuthVC;
            paymentAuthVC = [PKPaymentAuthorizationViewController
                             stp_controllerWithPaymentRequest:paymentRequest
                             apiClient:self.apiClient
                             onShippingAddressSelection:shippingAddressHandler
                             onShippingMethodSelection:shippingMethodHandler
                             onPaymentAuthorization:paymentHandler
                             onTokenCreation:applePayTokenHandler
                             onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
                                 [self.hostViewController dismissViewControllerAnimated:YES completion:^{
                                     [self didFinishWithStatus:status
                                                         error:error];
                                 }];
                             }];
            [self.hostViewController presentViewController:paymentAuthVC
                                                  animated:YES
                                                completion:nil];
        }
        else {
            // TODO:
            // This is a non-concrete method (eg just a type they want to use)
            // Need to convert to an actual source and then re-call requestPayment
        }
    }] onFailure:^(NSError *error) {
        STRONG(self);
        [self didFinishWithStatus:STPPaymentStatusError error:error];
    }];
}

- (void)didFinishWithStatus:(STPPaymentStatus)status
                      error:(nullable NSError *)error {
    self.state = STPPaymentContextStateNone;
    [self.delegate paymentContext:self
              didFinishWithStatus:status
                            error:error];
}

- (PKPaymentRequest *)buildPaymentRequest {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    if (!self.configuration.appleMerchantIdentifier || !self.paymentAmount) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.configuration.appleMerchantIdentifier];

    NSArray<PKPaymentSummaryItem *> *summaryItems = self.paymentSummaryItems;
    paymentRequest.paymentSummaryItems = summaryItems;
    paymentRequest.requiredBillingAddressFields = [STPAddress applePayAddressFieldsFromBillingAddressFields:self.configuration.requiredBillingAddressFields];
    paymentRequest.requiredShippingAddressFields = self.configuration.requiredShippingAddressFields;
    paymentRequest.currencyCode = self.paymentCurrency.uppercaseString;
    if (self.selectedShippingMethod != nil) {
        NSMutableArray<PKShippingMethod *>* orderedShippingMethods = [self.shippingMethods mutableCopy];
        [orderedShippingMethods removeObject:self.selectedShippingMethod];
        [orderedShippingMethods insertObject:self.selectedShippingMethod atIndex:0];
        paymentRequest.shippingMethods = orderedShippingMethods;
    }
    else {
        paymentRequest.shippingMethods = self.shippingMethods;
    }
    if ([paymentRequest respondsToSelector:@selector(shippingType)]) {
        paymentRequest.shippingType = [[self class] pkShippingType:self.configuration.shippingType];;
    }
    if (self.shippingAddress != nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        // Using shippingContact if available to work around an iOS10 bug:
        // https://openradar.appspot.com/radar?id=5518219632705536
        if ([paymentRequest respondsToSelector:@selector(shippingContact)]) {
            paymentRequest.shippingContact = [self.shippingAddress PKContactValue];
        }
        else {
            paymentRequest.shippingAddress = [self.shippingAddress ABRecordValue];
        }
#pragma clang diagnostic pop
    }
    return paymentRequest;
}

+ (PKShippingType)pkShippingType:(STPShippingType)shippingType {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    switch (shippingType) {
        case STPShippingTypeShipping:
            return PKShippingTypeShipping;
        case STPShippingTypeDelivery:
            return PKShippingTypeDelivery;
    }
}

static char kSTPPaymentCoordinatorAssociatedObjectKey;

- (void)artificiallyRetain:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


