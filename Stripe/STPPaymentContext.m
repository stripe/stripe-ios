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
#import "STPCustomerContext.h"
#import "STPDispatchFunctions.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "STPPaymentContextAmountModel.h"
#import "STPPaymentOptionTuple.h"
#import "STPPromise.h"
#import "STPShippingMethodsViewController.h"
#import "STPWeakStrongMacros.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

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

@interface STPPaymentContext() <STPPaymentOptionsViewControllerDelegate, STPShippingAddressViewControllerDelegate>

@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) STPTheme *theme;
@property (nonatomic) id<STPBackendAPIAdapter> apiAdapter;
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPPromise<STPPaymentOptionTuple *> *loadingPromise;

// these wrap hostViewController's promises because the hostVC is nil at init-time
@property (nonatomic) STPVoidPromise *willAppearPromise;
@property (nonatomic) STPVoidPromise *didAppearPromise;

@property (nonatomic, weak) STPPaymentOptionsViewController *paymentOptionsViewController;
@property (nonatomic) id<STPPaymentOption> selectedPaymentOption;
@property (nonatomic) NSArray<id<STPPaymentOption>> *paymentOptions;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) PKShippingMethod *selectedShippingMethod;
@property (nonatomic) NSArray<PKShippingMethod *> *shippingMethods;

@property (nonatomic, assign) STPPaymentContextState state;

@property (nonatomic) STPPaymentContextAmountModel *paymentAmountModel;
@property (nonatomic) BOOL shippingAddressNeedsVerification;

// If hostViewController was set to a nav controller, the original VC on top of the stack
@property (nonatomic, weak) UIViewController *originalTopViewController;
@property (nonatomic, nullable) PKPaymentAuthorizationViewController *applePayVC;

@end

@implementation STPPaymentContext

- (instancetype)initWithCustomerContext:(STPCustomerContext *)customerContext {
    return [self initWithAPIAdapter:customerContext];
}

- (instancetype)initWithCustomerContext:(STPCustomerContext *)customerContext
                          configuration:(STPPaymentConfiguration *)configuration
                                  theme:(STPTheme *)theme {
    return [self initWithAPIAdapter:customerContext
                      configuration:configuration
                              theme:theme];
}

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
        _paymentCountry = @"US";
        _paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithAmount:0];
        _modalPresentationStyle = UIModalPresentationFullScreen;
        if (@available(iOS 11, *)) {
            _largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        }
        _state = STPPaymentContextStateNone;
        [self retryLoading];
    }
    return self;
}

- (void)retryLoading {
    // Clear any cached customer object and attached payment methods before refetching
    if ([self.apiAdapter isKindOfClass:[STPCustomerContext class]]) {
        STPCustomerContext *customerContext = (STPCustomerContext *)self.apiAdapter;
        [customerContext clearCache];
    }
    WEAK(self);
    self.loadingPromise = [[[STPPromise<STPPaymentOptionTuple *> new] onSuccess:^(STPPaymentOptionTuple *tuple) {
        STRONG(self);
        self.paymentOptions = tuple.paymentOptions;
        self.selectedPaymentOption = tuple.selectedPaymentOption;
    }] onFailure:^(NSError * _Nonnull error) {
        STRONG(self);
        if (self.hostViewController) {
            [self.didAppearPromise onSuccess:^(__unused id value) {
                if (self.paymentOptionsViewController) {
                    [self appropriatelyDismissPaymentOptionsViewController:self.paymentOptionsViewController completion:^{
                        [self.delegate paymentContext:self didFailToLoadWithError:error];
                    }];
                } else {
                    [self.delegate paymentContext:self didFailToLoadWithError:error];
                }
            }];
        }
    }];
    [self.apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable retrieveCustomerError) {
        stpDispatchToMainThreadIfNecessary(^{
            STRONG(self);
            if (!self) {
                return;
            }
            if (retrieveCustomerError) {
                [self.loadingPromise fail:retrieveCustomerError];
                return;
            }
            if (!self.shippingAddress && customer.shippingAddress) {
                self.shippingAddress = customer.shippingAddress;
                self.shippingAddressNeedsVerification = YES;
            }

            [self.apiAdapter listPaymentMethodsForCustomerWithCompletion:^(NSArray<STPPaymentMethod *> * _Nullable paymentMethods, NSError * _Nullable error) {
                STRONG(self);
                stpDispatchToMainThreadIfNecessary(^{
                    if (error) {
                        [self.loadingPromise fail:error];
                        return;
                    }
                    STPPaymentOptionTuple *paymentTuple = [STPPaymentOptionTuple tupleFilteredForUIWithPaymentMethods:paymentMethods selectedPaymentMethod:self.defaultPaymentMethod configuration:self.configuration];
                    [self.loadingPromise succeed:paymentTuple];
                });
            }];
        });
    }];
}

- (BOOL)loading {
    return !self.loadingPromise.completed;
}

// Disable transition animations in tests
- (BOOL)transitionAnimationsEnabled {
    return NSClassFromString(@"XCTest") == nil;
}

- (void)setHostViewController:(UIViewController *)hostViewController {
    NSCAssert(_hostViewController == nil, @"You cannot change the hostViewController on an STPPaymentContext after it's already been set.");
    _hostViewController = hostViewController;
    if ([hostViewController isKindOfClass:[UINavigationController class]]) {
        self.originalTopViewController = ((UINavigationController *)hostViewController).topViewController;
    }
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

- (STPPromise<STPPaymentOptionTuple *> *)currentValuePromise {
    WEAK(self);
    return (STPPromise<STPPaymentOptionTuple *> *)[self.loadingPromise map:^id _Nonnull(__unused STPPaymentOptionTuple *value) {
        STRONG(self);
        return [STPPaymentOptionTuple tupleWithPaymentOptions:self.paymentOptions
                                        selectedPaymentOption:self.selectedPaymentOption];
    }];
}

- (void)setPrefilledInformation:(STPUserInformation *)prefilledInformation {
    _prefilledInformation = prefilledInformation;
    if (prefilledInformation.shippingAddress && !self.shippingAddress) {
        self.shippingAddress = prefilledInformation.shippingAddress;
        self.shippingAddressNeedsVerification = YES;
    }
}

- (void)setPaymentOptions:(NSArray<id<STPPaymentOption>> *)paymentOptions {
    _paymentOptions = [paymentOptions sortedArrayUsingComparator:^NSComparisonResult(id<STPPaymentOption> obj1, id<STPPaymentOption> obj2) {
        Class applePayKlass = [STPApplePayPaymentOption class];
        Class paymentMethodCardKlass = [STPPaymentMethod class];
        if ([obj1 isKindOfClass:applePayKlass]) {
            return NSOrderedAscending;
        } else if ([obj2 isKindOfClass:applePayKlass]) {
            return NSOrderedDescending;
        }
        if ([obj1 isKindOfClass:paymentMethodCardKlass] &&
            [obj2 isKindOfClass:paymentMethodCardKlass]) {
            return [[((STPPaymentMethod *)obj1) label]
                    compare:[((STPPaymentMethod *)obj2) label]];
        }
        return NSOrderedSame;
    }];
}

- (void)setSelectedPaymentOption:(id<STPPaymentOption>)selectedPaymentOption {
    if (selectedPaymentOption && ![self.paymentOptions containsObject:selectedPaymentOption]) {
        self.paymentOptions = [self.paymentOptions arrayByAddingObject:selectedPaymentOption];
    }
    if (![_selectedPaymentOption isEqual:selectedPaymentOption]) {
        _selectedPaymentOption = selectedPaymentOption;
        stpDispatchToMainThreadIfNecessary(^{
            [self.delegate paymentContextDidChange:self];
        });
    }
}


- (void)setPaymentAmount:(NSInteger)paymentAmount {
    self.paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithAmount:paymentAmount];
}

- (NSInteger)paymentAmount {
    return [self.paymentAmountModel paymentAmountWithCurrency:self.paymentCurrency
                                               shippingMethod:self.selectedShippingMethod];
}

- (void)setPaymentSummaryItems:(NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems {
    self.paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithPaymentSummaryItems:paymentSummaryItems];
}

- (NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems {
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

- (void)removePaymentOption:(id<STPPaymentOption>)paymentOptionToRemove {
    // Remove payment method from cached representation
    NSMutableArray *paymentOptions = [self.paymentOptions mutableCopy];
    [paymentOptions removeObject:paymentOptionToRemove];
    self.paymentOptions = paymentOptions;

    // Elect new selected payment method if needed
    if ([self.selectedPaymentOption isEqual:paymentOptionToRemove]) {
        self.selectedPaymentOption = self.paymentOptions.firstObject;
    }
}

#pragma mark - Payment Methods

- (void)presentPaymentOptionsViewController {
    [self presentPaymentOptionsViewControllerWithNewState:STPPaymentContextStateShowingRequestedViewController];
}

- (void)presentPaymentOptionsViewControllerWithNewState:(STPPaymentContextState)state {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushPaymentOptionsViewController on it. Next time, set the hostViewController property first!");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        if (self.state == STPPaymentContextStateNone) {
            self.state = state;
            STPPaymentOptionsViewController *paymentOptionsViewController = [[STPPaymentOptionsViewController alloc] initWithPaymentContext:self];
            self.paymentOptionsViewController = paymentOptionsViewController;
            paymentOptionsViewController.prefilledInformation = self.prefilledInformation;
            paymentOptionsViewController.defaultPaymentMethod = self.defaultPaymentMethod;
            paymentOptionsViewController.paymentOptionsViewControllerFooterView = self.paymentOptionsViewControllerFooterView;
            paymentOptionsViewController.addCardViewControllerFooterView = self.addCardViewControllerFooterView;
            if (@available(iOS 11, *)) {
                paymentOptionsViewController.navigationItem.largeTitleDisplayMode = self.largeTitleDisplayMode;
            }

            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentOptionsViewController];
            navigationController.navigationBar.stp_theme = self.theme;
            if (@available(iOS 11, *)) {
                navigationController.navigationBar.prefersLargeTitles = YES;
            }
            navigationController.modalPresentationStyle = self.modalPresentationStyle;
            [self.hostViewController presentViewController:navigationController
                                                  animated:[self transitionAnimationsEnabled]
                                                completion:nil];
        }
    }];
}

- (void)pushPaymentOptionsViewController {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushPaymentOptionsViewController on it. Next time, set the hostViewController property first!");
    UINavigationController *navigationController;
    if ([self.hostViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)self.hostViewController;
    } else {
        navigationController = self.hostViewController.navigationController;
    }
    NSCAssert(self.hostViewController != nil, @"The payment context's hostViewController is not a navigation controller, or is not contained in one. Either make sure it is inside a navigation controller before calling pushPaymentOptionsViewController, or call presentPaymentOptionsViewController instead.");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        if (self.state == STPPaymentContextStateNone) {
            self.state = STPPaymentContextStateShowingRequestedViewController;

            STPPaymentOptionsViewController *paymentOptionsViewController = [[STPPaymentOptionsViewController alloc] initWithPaymentContext:self];
            self.paymentOptionsViewController = paymentOptionsViewController;
            paymentOptionsViewController.prefilledInformation = self.prefilledInformation;
            paymentOptionsViewController.defaultPaymentMethod = self.defaultPaymentMethod;
            paymentOptionsViewController.paymentOptionsViewControllerFooterView = self.paymentOptionsViewControllerFooterView;
            paymentOptionsViewController.addCardViewControllerFooterView = self.addCardViewControllerFooterView;
            if (@available(iOS 11, *)) {
                paymentOptionsViewController.navigationItem.largeTitleDisplayMode = self.largeTitleDisplayMode;
            }

            [navigationController pushViewController:paymentOptionsViewController
                                            animated:[self transitionAnimationsEnabled]];
        }
    }];
}

- (void)paymentOptionsViewController:(__unused STPPaymentOptionsViewController *)paymentOptionsViewController
              didSelectPaymentOption:(id<STPPaymentOption>)paymentOption {
    self.selectedPaymentOption = paymentOption;
}

- (void)paymentOptionsViewControllerDidFinish:(STPPaymentOptionsViewController *)paymentOptionsViewController {
    [self appropriatelyDismissPaymentOptionsViewController:paymentOptionsViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            self.state = STPPaymentContextStateNone;
            [self requestPayment];
        }
        else {
            self.state = STPPaymentContextStateNone;
        }
    }];
}

- (void)paymentOptionsViewControllerDidCancel:(STPPaymentOptionsViewController *)paymentOptionsViewController {
    [self appropriatelyDismissPaymentOptionsViewController:paymentOptionsViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                error:nil];
        }
        else {
            self.state = STPPaymentContextStateNone;
        }
    }];
}

- (void)paymentOptionsViewController:(__unused STPPaymentOptionsViewController *)paymentOptionsViewController
              didFailToLoadWithError:(__unused NSError *)error {
    // we'll handle this ourselves when the loading promise fails.
}

- (void)appropriatelyDismissPaymentOptionsViewController:(STPPaymentOptionsViewController *)viewController
                                              completion:(STPVoidBlock)completion {
    if ([viewController stp_isAtRootOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [viewController.presentingViewController dismissViewControllerAnimated:[self transitionAnimationsEnabled]
                                                                    completion:^{
            self.paymentOptionsViewController = nil;
            if (completion) {
                completion();
            }
        }];
    } else {
        // otherwise, we've been pushed onto the stack.
        UIViewController *destinationViewController = self.hostViewController;
        // If hostViewController is a nav controller, pop to the original VC on top of the stack.
        if ([self.hostViewController isKindOfClass:[UINavigationController class]]) {
            destinationViewController = self.originalTopViewController;
        }
        [viewController.navigationController stp_popToViewController:destinationViewController
                                                            animated:[self transitionAnimationsEnabled]
                                                          completion:^{
            self.paymentOptionsViewController = nil;
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
            if (@available(iOS 11, *)) {
                addressViewController.navigationItem.largeTitleDisplayMode = self.largeTitleDisplayMode;
            }
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addressViewController];
            navigationController.navigationBar.stp_theme = self.theme;
            if (@available(iOS 11, *)) {
                navigationController.navigationBar.prefersLargeTitles = YES;
            }
            navigationController.modalPresentationStyle = self.modalPresentationStyle;
            [self.hostViewController presentViewController:navigationController
                                                  animated:[self transitionAnimationsEnabled]
                                                completion:nil];
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
            if (@available(iOS 11, *)) {
                addressViewController.navigationItem.largeTitleDisplayMode = self.largeTitleDisplayMode;
            }
            [navigationController pushViewController:addressViewController
                                            animated:[self transitionAnimationsEnabled]];
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
    self.shippingAddressNeedsVerification = NO;
    self.selectedShippingMethod = method;
    [self.delegate paymentContextDidChange:self];
    if ([self.apiAdapter respondsToSelector:@selector(updateCustomerWithShippingAddress:completion:)]) {
        [self.apiAdapter updateCustomerWithShippingAddress:self.shippingAddress completion:nil];
    }
    [self appropriatelyDismissViewController:addressViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            self.state = STPPaymentContextStateNone;
            [self requestPayment];
        } else {
            self.state = STPPaymentContextStateNone;
        }
    }];
}

- (void)appropriatelyDismissViewController:(UIViewController *)viewController
                                completion:(STPVoidBlock)completion {
    if ([viewController stp_isAtRootOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [viewController.presentingViewController dismissViewControllerAnimated:[self transitionAnimationsEnabled]
                                                                    completion:^{
            if (completion) {
                completion();
            }
        }];
    } else {
        // otherwise, we've been pushed onto the stack.
        UIViewController *destinationViewController = self.hostViewController;
        // If hostViewController is a nav controller, pop to the original VC on top of the stack.
        if ([self.hostViewController isKindOfClass:[UINavigationController class]]) {
            destinationViewController = self.originalTopViewController;
        }
        [viewController.navigationController stp_popToViewController:destinationViewController
                                                            animated:[self transitionAnimationsEnabled]
                                                          completion:^{
            if (completion) {
                completion();
            }
        }];
    }
}

#pragma mark - Request Payment

- (BOOL)requestPaymentShouldPresentShippingViewController {
    BOOL shippingAddressRequired = self.configuration.requiredShippingAddressFields.count > 0;
    BOOL shippingAddressIncomplete = ![self.shippingAddress containsRequiredShippingAddressFields:self.configuration.requiredShippingAddressFields];
    BOOL shippingMethodRequired = (self.configuration.shippingType == STPShippingTypeShipping &&
                                   [self.delegate respondsToSelector:@selector(paymentContext:didUpdateShippingAddress:completion:)] &&
                                   !self.selectedShippingMethod);
    BOOL verificationRequired = self.configuration.verifyPrefilledShippingAddress && self.shippingAddressNeedsVerification;
    // true if STPShippingVC should be presented to collect or verify a shipping address
    BOOL shouldPresentShippingAddress = (shippingAddressRequired && (shippingAddressIncomplete || verificationRequired));
    // this handles a corner case where STPShippingVC should be presented because:
    // - shipping address has been pre-filled
    // - no verification is required, but the user still needs to enter a shipping method
    BOOL shouldPresentShippingMethods = (shippingAddressRequired &&
                                         !shippingAddressIncomplete &&
                                         !verificationRequired &&
                                         shippingMethodRequired);
    return (shouldPresentShippingAddress || shouldPresentShippingMethods);
}

- (void)requestPayment {
    WEAK(self);
    [[[self.didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
        STRONG(self);
        return self.loadingPromise;
    }] onSuccess:^(__unused STPPaymentOptionTuple *tuple) {
        STRONG(self);
        if (!self) {
            return;
        }

        if (self.state != STPPaymentContextStateNone) {
            return;
        }

        if (!self.selectedPaymentOption) {
            [self presentPaymentOptionsViewControllerWithNewState:STPPaymentContextStateRequestingPayment];
        }
        else if ([self requestPaymentShouldPresentShippingViewController]) {
            [self presentShippingViewControllerWithNewState:STPPaymentContextStateRequestingPayment];
        }
        else if ([self.selectedPaymentOption isKindOfClass:[STPPaymentMethod class]]) {
            self.state = STPPaymentContextStateRequestingPayment;
            STPPaymentResult *result = [[STPPaymentResult alloc] initWithPaymentMethod:(STPPaymentMethod *)self.selectedPaymentOption];
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
        else if ([self.selectedPaymentOption isKindOfClass:[STPApplePayPaymentOption class]]) {
            NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext. Next time, set the hostViewController property first!");
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
                self.shippingAddress = [[STPAddress alloc] initWithPKContact:payment.shippingContact];
                self.shippingAddressNeedsVerification = NO;
                [self.delegate paymentContextDidChange:self];
                if ([self.apiAdapter isKindOfClass:[STPCustomerContext class]]) {
                    STPCustomerContext *customerContext = (STPCustomerContext *)self.apiAdapter;
                    [customerContext updateCustomerWithShippingAddress:self.shippingAddress completion:nil];
                }
            };
            STPApplePayPaymentMethodHandlerBlock applePayPaymentMethodHandler = ^(STPPaymentMethod *paymentMethod, STPErrorBlock completion) {
                [self.apiAdapter attachPaymentMethodToCustomer:paymentMethod completion:^(NSError *attachPaymentMethodError) {
                    stpDispatchToMainThreadIfNecessary(^{
                        if (attachPaymentMethodError) {
                            completion(attachPaymentMethodError);
                        } else {
                            STPPaymentResult *result = [[STPPaymentResult alloc] initWithPaymentMethod:paymentMethod];
                            [self.delegate paymentContext:self didCreatePaymentResult:result completion:^(NSError * error) {
                                // for Apple Pay, the didFinishWithStatus callback is fired later when Apple Pay VC finishes
                                if (error) {
                                    completion(error);
                                } else {
                                    completion(nil);
                                }
                            }];
                        }
                    });
                }];
            };
            self.applePayVC = [PKPaymentAuthorizationViewController
                               stp_controllerWithPaymentRequest:paymentRequest
                               apiClient:self.apiClient
                               onShippingAddressSelection:shippingAddressHandler
                               onShippingMethodSelection:shippingMethodHandler
                               onPaymentAuthorization:paymentHandler
                               onTokenCreation:applePayPaymentMethodHandler
                               onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
                                   if (self.applePayVC.presentingViewController != nil) {
                                       [self.hostViewController dismissViewControllerAnimated:[self transitionAnimationsEnabled]
                                                                                   completion:^{
                                                                                       [self didFinishWithStatus:status error:error];
                                                                                   }];
                                   } else {
                                       [self didFinishWithStatus:status error:error];
                                   }
                                   self.applePayVC = nil;
                               }];
            [self.hostViewController presentViewController:self.applePayVC
                                                  animated:[self transitionAnimationsEnabled]
                                                completion:nil];
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
    if (!self.configuration.appleMerchantIdentifier || !self.paymentAmount) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.configuration.appleMerchantIdentifier country:self.paymentCountry currency:self.paymentCurrency];

    NSArray<PKPaymentSummaryItem *> *summaryItems = self.paymentSummaryItems;
    paymentRequest.paymentSummaryItems = summaryItems;
    paymentRequest.requiredBillingAddressFields = [STPAddress applePayAddressFieldsFromBillingAddressFields:self.configuration.requiredBillingAddressFields];

    if (@available(iOS 11, *)) {
        NSSet<PKContactField> *requiredFields = [STPAddress pkContactFieldsFromStripeContactFields:self.configuration.requiredShippingAddressFields];
        if (requiredFields) {
            paymentRequest.requiredShippingContactFields = requiredFields;
        }
    }
    else {
        paymentRequest.requiredShippingAddressFields = [STPAddress pkAddressFieldsFromStripeContactFields:self.configuration.requiredShippingAddressFields];
    }

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

    paymentRequest.shippingType = [[self class] pkShippingType:self.configuration.shippingType];;

    if (self.shippingAddress != nil) {
        paymentRequest.shippingContact = [self.shippingAddress PKContactValue];
    }
    return paymentRequest;
}

+ (PKShippingType)pkShippingType:(STPShippingType)shippingType {
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

#pragma mark - STPAuthenticationContext

- (UIViewController *)authenticationPresentingViewController {
    return self.hostViewController;
}

- (void)prepareAuthenticationContextForPresentation:(STPVoidBlock)completion {
    if (self.applePayVC && self.applePayVC.presentingViewController != nil) {
        [self.hostViewController dismissViewControllerAnimated:[self transitionAnimationsEnabled]
                                                    completion:^{
                                                        completion();
                                                    }];
    } else {
        completion();
    }
}

@end


