//
//  STPPaymentContext.m
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import <objc/runtime.h>

#import "NSError+STPPaymentContext.h"
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
#import "STPSourceInfoViewController.h"
#import "STPSourcePrecheckParams.h"
#import "STPSourcePrecheckResult.h"
#import "STPSourceProtocol.h"
#import "STPWeakStrongMacros.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

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

- (void)dealloc {
    if (self.configuration.cancelSourceURLRedirectBlock) {
        self.configuration.cancelSourceURLRedirectBlock();
    }
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
    stpDispatchToMainThreadIfNecessary(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidBeginNotification object:self];
    });
    [self.apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable error) {
        stpDispatchToMainThreadIfNecessary(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidEndNotification object:self];
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
        } else {
            self.state = STPPaymentContextStateNone;
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
        else if (self.configuration.requiredShippingAddressFields != PKAddressFieldNone &&
                 !self.shippingAddress) {
            [self presentShippingViewControllerWithNewState:STPPaymentContextStateRequestingPayment];
        }
        else if ([self.selectedPaymentMethod isKindOfClass:[STPCard class]]) {
            [self requestSynchronousSourcePayment:(STPCard *)self.selectedPaymentMethod];
        }
        else if ([self.selectedPaymentMethod isKindOfClass:[STPSource class]]) {
            [self requestSourcePayment:(STPSource *)self.selectedPaymentMethod];
        }
        else if ([self.selectedPaymentMethod isEqual:[STPPaymentMethodType applePay]]) {
            [self requestApplePayPayment];
        }
        else if ([self.selectedPaymentMethod isKindOfClass:[STPPaymentMethodType class]]) {
            [self requestAbstractPaymentMethodTypePayment:(STPPaymentMethodType *)self.selectedPaymentMethod];
        }
        else {
            // Unsupported payment method
            [self didFinishWithStatus:STPPaymentStatusError
                                error:[NSError stp_paymentContextUnsupportedPaymentMethodError]];
        }
    }] onFailure:^(NSError *error) {
        STRONG(self);
        [self didFinishWithStatus:STPPaymentStatusError error:error];
    }];
}

- (void)requestSourceFlowNonePayment:(STPSource *)source {
    if (source.flow != STPSourceFlowNone) {
        return;
    }

    if (self.state != STPPaymentContextStateNone) {
        return;
    }

    if (source.type == STPSourceTypeCard) {
        // Cards have extra steps to see if 3DS is required
        [self requestCardSourcePayment:source];

    }
    else {
        // Else Just pass this source along for charging on their backend
        [self requestSynchronousSourcePayment:source];
    }
}

- (void)requestSynchronousSourcePayment:(id<STPSourceProtocol>)source {
    if (self.state != STPPaymentContextStateNone) {
        return;
    }

    // This is an STPCard or a source with source flow = none.
    // If its a card source we have already decided to not do 3ds

    self.state = STPPaymentContextStateRequestingPayment;

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

- (void)requestCardSourcePayment:(STPSource *)source {
    if (self.state != STPPaymentContextStateNone) {
        return;
    }

    if (source.type != STPSourceTypeCard) {
        return;
    }

    STPSourceCard3DSecureStatus threeDSecureStatus;

    if (source.cardDetails != nil) {
        threeDSecureStatus = source.cardDetails.threeDSecure;
    }
    else {
        threeDSecureStatus = STPSourceCard3DSecureStatusNotSupported;
    }

    STPThreeDSecureSupportType threeDSecureMethodToUse = self.configuration.threeDSecureSupportTypeBlock();

    switch (threeDSecureMethodToUse) {
        case STPThreeDSecureSupportTypeStatic: {
            switch (threeDSecureStatus) {
                case STPSourceCard3DSecureStatusRequired:
                case STPSourceCard3DSecureStatusOptional:
                    [self requestThreeDSSourceCreationAndPayment:source];
                    break;
                case STPSourceCard3DSecureStatusNotSupported:
                case STPSourceCard3DSecureStatusUnknown:
                    [self requestSynchronousSourcePayment:source];
                    break;
            }
        }
            break;
        case STPThreeDSecureSupportTypeDynamic: {
            switch (threeDSecureStatus) {
                case STPSourceCard3DSecureStatusRequired:
                    [self requestThreeDSSourceCreationAndPayment:source];
                    break;
                case STPSourceCard3DSecureStatusOptional:
                    [self requestPrecheckAndTakeRequiredActions:source];
                    break;
                case STPSourceCard3DSecureStatusNotSupported:
                case STPSourceCard3DSecureStatusUnknown:
                    [self requestSynchronousSourcePayment:source];
                    break;
            }
        }
            break;
        case STPThreeDSecureSupportTypeDisabled:
            [self requestSynchronousSourcePayment:source];
            break;
    }
}

- (void)requestPrecheckAndTakeRequiredActions:(STPSource *)source {
    if (self.state != STPPaymentContextStateNone) {
        return;
    }

    self.state = STPPaymentContextStateRequestingPayment;

    STPSourcePrecheckParams *precheckParams = [STPSourcePrecheckParams new];
    precheckParams.sourceID = source.stripeID;
    precheckParams.paymentAmount = @(self.paymentAmount);
    precheckParams.paymentCurrency = self.paymentCurrency;
    // TODO: method for merchant to add metadata/additional fields

    STPSourcePrecheckCompletionBlock completion = ^(STPSourcePrecheckResult * _Nullable precheckResult, NSError * _Nullable error) {
        self.state = STPPaymentContextStateNone;
        if (error
            || precheckResult == nil) {
            /* 
             Fallback to "static" behavior if there's an error getting the precheck
             
             Rules are run again on actual charge, so there is no chance that
             invalid charges will get through
             */
            [self requestThreeDSSourceCreationAndPayment:source];
        }
        else {
            if ([precheckResult.requiredActions containsObject:STPSourcePrecheckRequiredActionCreateThreeDSecureSource]) {
                /*
                 If precheck said we need 3DS, don't allow falling back to
                 charging the non-3DS card
                 */
                [self requestThreeDSSourceCreationAndPayment:source
                                    allowCardSourceOnFailure:NO];
            }
            else {
                [self requestSynchronousSourcePayment:source];
            }
        }
    };

    [self.apiClient precheckSourceWithParams:precheckParams
                                  completion:completion];
}

- (void)requestThreeDSSourceCreationAndPayment:(STPSource *)cardSource {
    /*
     If the card says three d secure is required, an error to create a 3DS source
     should error. Otherwise, allow continuing payment with card source.
     */
    [self requestThreeDSSourceCreationAndPayment:cardSource
                        allowCardSourceOnFailure:(cardSource.cardDetails.threeDSecure != STPSourceCard3DSecureStatusRequired)];
}

- (void)requestThreeDSSourceCreationAndPayment:(STPSource *)cardSource
                      allowCardSourceOnFailure:(BOOL)allowCardSourceOnFailure {
    if (self.state != STPPaymentContextStateNone) {
        return;
    }

    self.state = STPPaymentContextStateRequestingPayment;

    /*
     This is a card source we have decided needs to be 3DS'd.
     User checked out with a card source, we want to create a 3DS source
     and request payment with that if possible
     
     At this point we should only be receiving card sources that have
     three_d_secure types of required or optional (not_supported are filtered earlier)

     Logic should be:
        Try to create 3DS source from the card source.
        If it could not be created...
            If we're allowed to fallback to charging the card and error code is `payment_method_not_available`, then charge the original card source
            Else finish with STPPaymentStatusError
        If 3DS source was created successfully, check its status
            If pending, perform redirect flow source as normal
            If chargeable, no further action required, return STPPaymentStatusSuccess (payment happens on webhook)
            If failed, return Error or fallback to charging original card source if we are allowed to

     */

    STPSourceParams *threeDSecureParams = [STPSourceParams threeDSecureParamsWithAmount:self.paymentAmount
                                                                               currency:self.paymentCurrency
                                                                              returnURL:self.configuration.returnURLBlock().absoluteString
                                                                                   card:cardSource.stripeID];
    threeDSecureParams.metadata = self.sourceInformation.metadata;

    STPSourceCompletionBlock threeDSSourceCompletion = ^(STPSource * _Nullable threeDSSource, NSError * _Nullable error) {
        if (error
            || threeDSSource == nil
            || threeDSSource.flow != STPSourceFlowRedirect) {
            if (allowCardSourceOnFailure
                && error.domain == StripeDomain
                && [error.userInfo[STPCardErrorCodeKey] isEqualToString:STPPaymentMethodNotAvailable]) {
                // This is a card that doesn't actually support 3ds and the card source didn't say 3ds was required
                // So we can just return the original card source to be charged
                self.state = STPPaymentContextStateNone;
                [self requestSynchronousSourcePayment:cardSource];

            }
            else {
                // Finish with an error
                [self didFinishWithStatus:STPPaymentStatusError
                                    error:error ?: [NSError stp_genericConnectionError]];
            }
        }
        else {
            // We successfully have a 3ds source
            switch (threeDSSource.status) {
                case STPSourceStatusPending:
                    // Do 3DS redirect
                    self.state = STPPaymentContextStateNone;
                    [self requestSourceFlowRedirectPayment:threeDSSource];
                    break;
                case STPSourceStatusFailed:
                    if (!allowCardSourceOnFailure) {
                        // If required, fail with error
                        [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                            error:nil];
                    }
                    else {
                        // If not required, charge original source
                        self.state = STPPaymentContextStateNone;
                        [self requestSynchronousSourcePayment:cardSource];
                    }

                    break;
                case STPSourceStatusConsumed:
                case STPSourceStatusChargeable:
                    // Success, we can just finish
                    // (charge will happen on webhook)
                    [self didFinishWithStatus:STPPaymentStatusSuccess
                                        error:nil];
                    break;
                case STPSourceStatusUnknown:
                case STPSourceStatusCanceled:
                    [self didFinishWithStatus:STPPaymentStatusError
                                        error:[NSError stp_paymentContextInvalidSourceStatusErrorWithStatus:threeDSSource.status]];
                    break;
            }
        }
    };


    [self.apiClient createSourceWithParams:threeDSecureParams
                                completion:threeDSSourceCompletion];
}


- (void)requestSourceFlowRedirectPayment:(STPSource *)source {
    if (source.flow != STPSourceFlowRedirect) {
        return;
    }

    if (self.state != STPPaymentContextStateNone) {
        return;
    }

    self.state = STPPaymentContextStateRequestingPayment;

    STPSourceCompletionBlock onRedirectCompletion = ^(STPSource *finishedSource, NSError *error) {
        stpDispatchToMainThreadIfNecessary(^{
            if (error) {
                // If the page load failed, we know that the redirect failed
                // and should return an error. Otherwise (e.g. if polling errored),
                // we don't know the status of the source and should return status pending.
                if (error.domain == StripeDomain && error.code == STPRedirectContextPageLoadError) {
                    [self didFinishWithStatus:STPPaymentStatusError error:[NSError stp_genericConnectionError]];
                } else {
                    [self didFinishWithStatus:STPPaymentStatusPending error:nil];
                }
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
                                            error:[NSError stp_paymentContextInvalidSourceStatusErrorWithStatus:finishedSource.status]];
                        break;
                    case STPSourceStatusUnknown:
                        [self didFinishWithStatus:STPPaymentStatusError
                                            error:[NSError stp_paymentContextInvalidSourceStatusErrorWithStatus:finishedSource.status]];
                        break;
                }
            }
        });
    };

    self.configuration.sourceURLRedirectBlock(self.apiClient,
                                              source,
                                              self.hostViewController,
                                              onRedirectCompletion);

}

- (void)requestSourcePayment:(STPSource *)source {
    if (self.state != STPPaymentContextStateNone) {
        return;
    }

    // Concrete source object, check flow to see if synchronous charge or webhook based

    switch (source.flow) {
        case STPSourceFlowNone:
            [self requestSourceFlowNonePayment:source];
            break;
        case STPSourceFlowRedirect:
            [self requestSourceFlowRedirectPayment:source];
            break;
        case STPSourceFlowReceiver:
        case STPSourceFlowCodeVerification:
        case STPSourceFlowUnknown:
            // We don't support this type
            [self didFinishWithStatus:STPPaymentStatusError
                                error:[NSError stp_paymentContextUnsupportedPaymentMethodError]];
            break;
    }
}

- (void)requestApplePayPayment {
    if (self.state != STPPaymentContextStateNone) {
        return;
    }

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
        stpDispatchToMainThreadIfNecessary(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidBeginNotification object:self];
        });
        [self.apiAdapter attachSourceToCustomer:token completion:^(NSError *tokenError) {
            stpDispatchToMainThreadIfNecessary(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidEndNotification object:self];
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

- (void)requestAbstractPaymentMethodTypePayment:(STPPaymentMethodType *)type {
    // This is a non-concrete method (eg just a type they want to use)
    // Need to convert to an actual source and then re-call requestPayment

    // We currently only support this for single use sources
    // Reusable types should be converted to concrete sources before reaching here
    // Apple pay is handled separately as it is a special case

    STPSourceInfoCompletionBlock completion = ^(STPSourceParams * _Nullable sourceParams) {
        STPVoidBlock vcCompletion = ^() {
            if (sourceParams) {
                if (self.sourceInformation.metadata) {
                    sourceParams.metadata = self.sourceInformation.metadata;
                }
                [self.apiClient createSourceWithParams:sourceParams completion:^(STPSource * _Nullable source, NSError * _Nullable error) {
                    if (source) {
                        self.state = STPPaymentContextStateNone;
                        [self requestSourcePayment:source];
                    }
                    else {
                        [self didFinishWithStatus:STPPaymentStatusError
                                            error:error ?: [NSError stp_genericConnectionError]];
                    }
                }];
            }
            else {
                // User cancelled
                [self didFinishWithStatus:STPPaymentStatusUserCancellation
                                    error:nil];
            }
        };

        if (self.hostViewController.presentedViewController) {
            [self.hostViewController dismissViewControllerAnimated:YES
                                                        completion:vcCompletion];
        }
        else {
            vcCompletion();
        }

    };

    STPSourceInfoViewController *sourceInfoVC = [[STPSourceInfoViewController alloc] initWithSourceType:type.sourceType
                                                                                                 amount:self.paymentAmount
                                                                                          configuration:self.configuration
                                                                                   prefilledInformation:self.prefilledInformation
                                                                                      sourceInformation:self.sourceInformation
                                                                                                  theme:self.theme
                                                                                             completion:completion];
    if (sourceInfoVC) {
        self.state = STPPaymentContextStateRequestingPayment;

        if (sourceInfoVC.completeSourceParams) {
            completion(sourceInfoVC.completeSourceParams);
        }
        else {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:sourceInfoVC];
            navigationController.navigationBar.stp_theme = self.theme;
            navigationController.modalPresentationStyle = self.modalPresentationStyle;
            [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
        }
    }
    else {
        // Unsupported source type
        [self didFinishWithStatus:STPPaymentStatusError
                            error:[NSError stp_paymentContextUnsupportedPaymentMethodError]];
    }
}

- (void)didFinishWithStatus:(STPPaymentStatus)status
                      error:(nullable NSError *)error {
    self.state = STPPaymentContextStateNone;
    [self.delegate paymentContext:self
              didFinishWithStatus:status
                            error:error];
}

#pragma mark - Apple Pay -

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


