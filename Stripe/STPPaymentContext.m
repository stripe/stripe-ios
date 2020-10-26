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
#import "STPAnalyticsClient.h"
#import "STPAddCardViewController+Private.h"
#import "STPCustomerContext+Private.h"
#import "STPDispatchFunctions.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "STPPaymentContextAmountModel.h"
#import "STPPaymentOptionTuple.h"
#import "STPPromise.h"
#import "STPShippingMethodsViewController.h"
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

+ (void)initialize{
    [[STPAnalyticsClient sharedClient] addClassToProductUsageIfNecessary:[self class]];
}

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
        _apiClient = [STPAPIClient sharedClient];
        _paymentCurrency = @"USD";
        _paymentCountry = @"US";
        _paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithAmount:0];
        _modalPresentationStyle = UIModalPresentationFullScreen;
        _largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
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
    __weak typeof(self) weakSelf = self;
    self.loadingPromise = [[[STPPromise<STPPaymentOptionTuple *> new] onSuccess:^(STPPaymentOptionTuple *tuple) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.paymentOptions = tuple.paymentOptions;
        strongSelf.selectedPaymentOption = tuple.selectedPaymentOption;
    }] onFailure:^(NSError * _Nonnull error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.hostViewController) {
            [strongSelf.didAppearPromise onSuccess:^(__unused id value) {
                if (strongSelf.paymentOptionsViewController) {
                    [strongSelf appropriatelyDismissPaymentOptionsViewController:strongSelf.paymentOptionsViewController completion:^{
                        [strongSelf.delegate paymentContext:strongSelf didFailToLoadWithError:error];
                    }];
                } else {
                    [strongSelf.delegate paymentContext:strongSelf didFailToLoadWithError:error];
                }
            }];
        }
    }];
    [self.apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable retrieveCustomerError) {
        stpDispatchToMainThreadIfNecessary(^{
            __strong typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (retrieveCustomerError) {
                [strongSelf.loadingPromise fail:retrieveCustomerError];
                return;
            }
            if (!strongSelf.shippingAddress && customer.shippingAddress) {
                strongSelf.shippingAddress = customer.shippingAddress;
                strongSelf.shippingAddressNeedsVerification = YES;
            }

            [strongSelf.apiAdapter listPaymentMethodsForCustomerWithCompletion:^(NSArray<STPPaymentMethod *> * _Nullable paymentMethods, NSError * _Nullable error) {
                __strong typeof(self) strongSelf2 = weakSelf;
                stpDispatchToMainThreadIfNecessary(^{
                    if (error) {
                        [strongSelf2.loadingPromise fail:error];
                        return;
                    }

                    if (self.defaultPaymentMethod == nil && [strongSelf2.apiAdapter isKindOfClass:[STPCustomerContext class]]) {
                        // Retrieve the last selected payment method saved by STPCustomerContext
                        [((STPCustomerContext *)strongSelf2.apiAdapter) retrieveLastSelectedPaymentMethodIDForCustomerWithCompletion:^(NSString * _Nullable paymentMethodID, NSError * _Nullable __unused _) {
                            __strong typeof(self) strongSelf3 = weakSelf;
                            STPPaymentOptionTuple *paymentTuple = [STPPaymentOptionTuple tupleFilteredForUIWithPaymentMethods:paymentMethods selectedPaymentMethod:paymentMethodID configuration:strongSelf3.configuration];
                            [strongSelf3.loadingPromise succeed:paymentTuple];
                        }];
                    } else {
                        STPPaymentOptionTuple *paymentTuple = [STPPaymentOptionTuple tupleFilteredForUIWithPaymentMethods:paymentMethods selectedPaymentMethod:self.defaultPaymentMethod configuration:strongSelf2.configuration];
                        [strongSelf2.loadingPromise succeed:paymentTuple];
                    }
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
    __weak typeof(self) weakSelf = self;
    [self.willAppearPromise voidOnSuccess:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.delegate == delegate) {
            [delegate paymentContextDidChange:strongSelf];
        }
    }];
}

- (STPPromise<STPPaymentOptionTuple *> *)currentValuePromise {
    __weak typeof(self) weakSelf = self;
    return (STPPromise<STPPaymentOptionTuple *> *)[self.loadingPromise map:^id _Nonnull(__unused STPPaymentOptionTuple *value) {
        __strong typeof(self) strongSelf = weakSelf;
        return [STPPaymentOptionTuple tupleWithPaymentOptions:strongSelf.paymentOptions
                                        selectedPaymentOption:strongSelf.selectedPaymentOption];
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
        if (selectedPaymentOption.reusable) {
            self.paymentOptions = [self.paymentOptions arrayByAddingObject:selectedPaymentOption];
        }
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
        } else if ([shippingMethods indexOfObject:self.selectedShippingMethod] == NSNotFound) {
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
    __weak typeof(self) weakSelf = self;
    [self.didAppearPromise voidOnSuccess:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        if (strongSelf.state == STPPaymentContextStateNone) {
            strongSelf.state = state;
            STPPaymentOptionsViewController *paymentOptionsViewController = [[STPPaymentOptionsViewController alloc] initWithPaymentContext:strongSelf];
            strongSelf.paymentOptionsViewController = paymentOptionsViewController;
            paymentOptionsViewController.prefilledInformation = strongSelf.prefilledInformation;
            paymentOptionsViewController.defaultPaymentMethod = strongSelf.defaultPaymentMethod;
            paymentOptionsViewController.paymentOptionsViewControllerFooterView = strongSelf.paymentOptionsViewControllerFooterView;
            paymentOptionsViewController.addCardViewControllerFooterView = strongSelf.addCardViewControllerFooterView;
            paymentOptionsViewController.navigationItem.largeTitleDisplayMode = strongSelf.largeTitleDisplayMode;

            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentOptionsViewController];
            navigationController.navigationBar.stp_theme = strongSelf.theme;
            navigationController.navigationBar.prefersLargeTitles = YES;
            navigationController.modalPresentationStyle = strongSelf.modalPresentationStyle;
            [strongSelf.hostViewController presentViewController:navigationController
                                                        animated:[strongSelf transitionAnimationsEnabled]
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
    __weak typeof(self) weakSelf = self;
    [self.didAppearPromise voidOnSuccess:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.state == STPPaymentContextStateNone) {
            strongSelf.state = STPPaymentContextStateShowingRequestedViewController;

            STPPaymentOptionsViewController *paymentOptionsViewController = [[STPPaymentOptionsViewController alloc] initWithPaymentContext:strongSelf];
            strongSelf.paymentOptionsViewController = paymentOptionsViewController;
            paymentOptionsViewController.prefilledInformation = strongSelf.prefilledInformation;
            paymentOptionsViewController.defaultPaymentMethod = strongSelf.defaultPaymentMethod;
            paymentOptionsViewController.paymentOptionsViewControllerFooterView = strongSelf.paymentOptionsViewControllerFooterView;
            paymentOptionsViewController.addCardViewControllerFooterView = strongSelf.addCardViewControllerFooterView;
            paymentOptionsViewController.navigationItem.largeTitleDisplayMode = strongSelf.largeTitleDisplayMode;

            [navigationController pushViewController:paymentOptionsViewController
                                            animated:[strongSelf transitionAnimationsEnabled]];
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
        } else {
            self.state = STPPaymentContextStateNone;
        }
    }];
}

- (void)paymentOptionsViewControllerDidCancel:(STPPaymentOptionsViewController *)paymentOptionsViewController {
    [self appropriatelyDismissPaymentOptionsViewController:paymentOptionsViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                error:nil];
        } else {
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
    __weak typeof(self) weakSelf = self;
    [self.didAppearPromise voidOnSuccess:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.state == STPPaymentContextStateNone) {
            strongSelf.state = state;

            STPShippingAddressViewController *addressViewController = [[STPShippingAddressViewController alloc] initWithPaymentContext:strongSelf];
            addressViewController.navigationItem.largeTitleDisplayMode = strongSelf.largeTitleDisplayMode;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addressViewController];
            navigationController.navigationBar.stp_theme = strongSelf.theme;
            navigationController.navigationBar.prefersLargeTitles = YES;
            navigationController.modalPresentationStyle = strongSelf.modalPresentationStyle;
            [strongSelf.hostViewController presentViewController:navigationController
                                                        animated:[strongSelf transitionAnimationsEnabled]
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
    __weak typeof(self) weakSelf = self;
    [self.didAppearPromise voidOnSuccess:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.state == STPPaymentContextStateNone) {
            strongSelf.state = STPPaymentContextStateShowingRequestedViewController;

            STPShippingAddressViewController *addressViewController = [[STPShippingAddressViewController alloc] initWithPaymentContext:strongSelf];
            addressViewController.navigationItem.largeTitleDisplayMode = strongSelf.largeTitleDisplayMode;
            [navigationController pushViewController:addressViewController
                                            animated:[strongSelf transitionAnimationsEnabled]];
        }
    }];
}

- (void)shippingAddressViewControllerDidCancel:(STPShippingAddressViewController *)addressViewController {
    [self appropriatelyDismissViewController:addressViewController completion:^{
        if (self.state == STPPaymentContextStateRequestingPayment) {
            [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                error:nil];
        } else {
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
    } else {
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
    __weak typeof(self) weakSelf = self;
    [[[self.didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
        __strong typeof(self) strongSelf = weakSelf;
        return strongSelf.loadingPromise;
    }] onSuccess:^(__unused STPPaymentOptionTuple *tuple) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        if (strongSelf.state != STPPaymentContextStateNone) {
            return;
        }

        if (!strongSelf.selectedPaymentOption) {
            [strongSelf presentPaymentOptionsViewControllerWithNewState:STPPaymentContextStateRequestingPayment];
        } else if ([strongSelf requestPaymentShouldPresentShippingViewController]) {
            [strongSelf presentShippingViewControllerWithNewState:STPPaymentContextStateRequestingPayment];
        } else if ([strongSelf.selectedPaymentOption isKindOfClass:[STPPaymentMethod class]] || [self.selectedPaymentOption isKindOfClass:[STPPaymentMethodParams class]]) {
            strongSelf.state = STPPaymentContextStateRequestingPayment;
            STPPaymentResult *result = [[STPPaymentResult alloc] initWithPaymentOption:strongSelf.selectedPaymentOption];
            [strongSelf.delegate paymentContext:self didCreatePaymentResult:result completion:^(STPPaymentStatus status, NSError * _Nullable error) {
                stpDispatchToMainThreadIfNecessary(^{
                    [strongSelf didFinishWithStatus:status error:error];
                });
            }];
        } else if ([strongSelf.selectedPaymentOption isKindOfClass:[STPApplePayPaymentOption class]]) {
            NSCAssert(strongSelf.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext. Next time, set the hostViewController property first!");
            strongSelf.state = STPPaymentContextStateRequestingPayment;
            PKPaymentRequest *paymentRequest = [strongSelf buildPaymentRequest];
            STPShippingAddressSelectionBlock shippingAddressHandler = ^(STPAddress *shippingAddress, STPShippingAddressValidationBlock completion) {
                // Apple Pay always returns a partial address here, so we won't
                // update self.shippingAddress or self.shippingMethods
                if ([strongSelf.delegate respondsToSelector:@selector(paymentContext:didUpdateShippingAddress:completion:)]) {
                    [strongSelf.delegate paymentContext:strongSelf didUpdateShippingAddress:shippingAddress completion:^(STPShippingStatus status, __unused NSError *shippingValidationError, NSArray<PKShippingMethod *> *shippingMethods, __unused PKShippingMethod *selectedMethod) {
                        completion(status, shippingMethods, strongSelf.paymentSummaryItems);
                    }];
                } else {
                    completion(STPShippingStatusValid, strongSelf.shippingMethods, strongSelf.paymentSummaryItems);
                }
            };
            STPShippingMethodSelectionBlock shippingMethodHandler = ^(PKShippingMethod *shippingMethod, STPPaymentSummaryItemCompletionBlock completion) {
                strongSelf.selectedShippingMethod = shippingMethod;
                [strongSelf.delegate paymentContextDidChange:strongSelf];
                completion(self.paymentSummaryItems);
            };
            STPPaymentAuthorizationBlock paymentHandler = ^(PKPayment *payment) {
                strongSelf.selectedShippingMethod = payment.shippingMethod;
                strongSelf.shippingAddress = [[STPAddress alloc] initWithPKContact:payment.shippingContact];
                strongSelf.shippingAddressNeedsVerification = NO;
                [strongSelf.delegate paymentContextDidChange:strongSelf];
                if ([strongSelf.apiAdapter isKindOfClass:[STPCustomerContext class]]) {
                    STPCustomerContext *customerContext = (STPCustomerContext *)strongSelf.apiAdapter;
                    [customerContext updateCustomerWithShippingAddress:strongSelf.shippingAddress completion:nil];
                }
            };
            STPApplePayPaymentMethodHandlerBlock applePayPaymentMethodHandler = ^(STPPaymentMethod *paymentMethod, STPPaymentStatusBlock completion) {
                [strongSelf.apiAdapter attachPaymentMethodToCustomer:paymentMethod completion:^(NSError *attachPaymentMethodError) {
                    stpDispatchToMainThreadIfNecessary(^{
                        if (attachPaymentMethodError) {
                            completion(STPPaymentStatusError, attachPaymentMethodError);
                        } else {
                            STPPaymentResult *result = [[STPPaymentResult alloc] initWithPaymentOption:paymentMethod];
                            [strongSelf.delegate paymentContext:strongSelf didCreatePaymentResult:result completion:^(STPPaymentStatus status, NSError * error) {
                                // for Apple Pay, the didFinishWithStatus callback is fired later when Apple Pay VC finishes
                                completion(status, error);
                            }];
                        }
                    });
                }];
            };
            strongSelf.applePayVC = [PKPaymentAuthorizationViewController
                                     stp_controllerWithPaymentRequest:paymentRequest
                                     apiClient:self.apiClient
                                     onShippingAddressSelection:shippingAddressHandler
                                     onShippingMethodSelection:shippingMethodHandler
                                     onPaymentAuthorization:paymentHandler
                                     onPaymentMethodCreation:applePayPaymentMethodHandler
                                     onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
                                         if (strongSelf.applePayVC.presentingViewController != nil) {
                                             [strongSelf.hostViewController dismissViewControllerAnimated:[strongSelf transitionAnimationsEnabled]
                                                                                               completion:^{
                                                                                                   [strongSelf didFinishWithStatus:status error:error];
                                                                                               }];
                                         } else {
                                             [strongSelf didFinishWithStatus:status error:error];
                                         }
                                         strongSelf.applePayVC = nil;
                                     }];
            [strongSelf.hostViewController presentViewController:strongSelf.applePayVC
                                                        animated:[strongSelf transitionAnimationsEnabled]
                                                      completion:nil];
        }
    }] onFailure:^(NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf didFinishWithStatus:STPPaymentStatusError error:error];
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


    NSSet<PKContactField> *requiredFields = [STPAddress applePayContactFieldsFromBillingAddressFields:self.configuration.requiredBillingAddressFields];
    if (requiredFields) {
        paymentRequest.requiredBillingContactFields = requiredFields;
    }

    NSSet<PKContactField> *shippingRequiredFields = [STPAddress pkContactFieldsFromStripeContactFields:self.configuration.requiredShippingAddressFields];
    if (requiredFields) {
        paymentRequest.requiredShippingContactFields = shippingRequiredFields;
    }

    paymentRequest.currencyCode = self.paymentCurrency.uppercaseString;
    if (self.selectedShippingMethod != nil) {
        NSMutableArray<PKShippingMethod *>* orderedShippingMethods = [self.shippingMethods mutableCopy];
        [orderedShippingMethods removeObject:self.selectedShippingMethod];
        [orderedShippingMethods insertObject:self.selectedShippingMethod atIndex:0];
        paymentRequest.shippingMethods = orderedShippingMethods;
    } else {
        paymentRequest.shippingMethods = self.shippingMethods;
    }

    paymentRequest.shippingType = [[self class] pkShippingType:self.configuration.shippingType];

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


