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
#import "UIViewController+Stripe_ParentViewController.h"
#import "STPPromise.h"
#import "STPCardTuple.h"
#import "STPPaymentMethodTuple.h"
#import "STPPaymentContext+Private.h"
#import "UIViewController+Stripe_Promises.h"
#import "UIViewController+Stripe_Alerts.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPWeakStrongMacros.h"
#import "STPPaymentContextAmountModel.h"
#import "STPShippingAddressViewController.h"
#import "STPShippingMethodsViewController.h"
#import "STPShippingMethod+Private.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPPaymentContext()<STPPaymentMethodsViewControllerDelegate, STPAddCardViewControllerDelegate, STPShippingAddressViewControllerDelegate>

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
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;
@property(nonatomic)STPAddress *shippingAddress;
@property(nonatomic)STPShippingMethod *selectedShippingMethod;
@property(nonatomic)NSArray<STPShippingMethod *> *shippingMethods;

@property(nonatomic)STPPaymentContextAmountModel *paymentAmountModel;

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
        self.paymentMethods = tuple.paymentMethods;
        self.selectedPaymentMethod = tuple.selectedPaymentMethod;
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
        STRONG(self);
        if (!self) {
            return;
        }
        if (error) {
            [self.loadingPromise fail:error];
            return;
        }
        STPCard *selectedCard;
        NSMutableArray<STPCard *> *cards = [NSMutableArray array];
        for (id<STPSource> source in customer.sources) {
            if ([source isKindOfClass:[STPCard class]]) {
                STPCard *card = (STPCard *)source;
                [cards addObject:card];
                if ([card.stripeID isEqualToString:customer.defaultSource.stripeID]) {
                    selectedCard = card;
                }
            }
        }
        STPCardTuple *tuple = [STPCardTuple tupleWithSelectedCard:selectedCard cards:cards];
        STPPaymentMethodTuple *paymentTuple = [STPPaymentMethodTuple tupleWithCardTuple:tuple applePayEnabled:self.configuration.applePayEnabled];
        [self.loadingPromise succeed:paymentTuple];
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
        return [STPPaymentMethodTuple tupleWithPaymentMethods:self.paymentMethods
                                        selectedPaymentMethod:self.selectedPaymentMethod];
    }];
}

- (void)setPaymentMethods:(NSArray<id<STPPaymentMethod>> *)paymentMethods {
    _paymentMethods = [paymentMethods sortedArrayUsingComparator:^NSComparisonResult(id<STPPaymentMethod> obj1, id<STPPaymentMethod> obj2) {
        Class applePayKlass = [STPApplePayPaymentMethod class];
        Class cardKlass = [STPCard class];
        if ([obj1 isKindOfClass:applePayKlass]) {
            return NSOrderedAscending;
        } else if ([obj2 isKindOfClass:applePayKlass]) {
            return NSOrderedDescending;
        }
        if ([obj1 isKindOfClass:cardKlass] && [obj2 isKindOfClass:cardKlass]) {
            return [[((STPCard *)obj1) label]
                    compare:[((STPCard *)obj2) label]];
        }
        return NSOrderedSame;
    }];
}

- (void)setSelectedPaymentMethod:(id<STPPaymentMethod>)selectedPaymentMethod {
    if (selectedPaymentMethod && ![self.paymentMethods containsObject:selectedPaymentMethod]) {
        self.paymentMethods = [self.paymentMethods arrayByAddingObject:selectedPaymentMethod];
    }
    if (![_selectedPaymentMethod isEqual:selectedPaymentMethod]) {
        _selectedPaymentMethod = selectedPaymentMethod;
        [self.delegate paymentContextDidChange:self];
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
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)
    self.paymentAmountModel = [[STPPaymentContextAmountModel alloc] initWithPaymentSummaryItems:paymentSummaryItems];
}

- (NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)
    return [self.paymentAmountModel paymentSummaryItemsWithCurrency:self.paymentCurrency
                                                        companyName:self.configuration.companyName
                                                     shippingMethod:self.selectedShippingMethod];
}

#pragma mark - Payment Methods

- (void)presentPaymentMethodsViewController {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushPaymentMethodsViewController on it. Next time, set the hostViewController property first!");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:self];
        self.paymentMethodsViewController = paymentMethodsViewController;
        paymentMethodsViewController.prefilledInformation = self.prefilledInformation;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsViewController];
        [navigationController.navigationBar stp_setTheme:self.theme];
        navigationController.modalPresentationStyle = self.modalPresentationStyle;
        [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
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
        STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:self];
        self.paymentMethodsViewController = paymentMethodsViewController;
        paymentMethodsViewController.prefilledInformation = self.prefilledInformation;
        [navigationController pushViewController:paymentMethodsViewController animated:YES];
    }];
}

- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController
              didSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    self.selectedPaymentMethod = paymentMethod;
}

- (void)paymentMethodsViewControllerDidFinish:(STPPaymentMethodsViewController *)paymentMethodsViewController {
    [self appropriatelyDismissPaymentMethodsViewController:paymentMethodsViewController completion:nil];
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

- (void)presentShippingInfoViewController {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling presentShippingInfoViewController on it. Next time, set the hostViewController property first!");
    WEAK(self);
    [self.didAppearPromise voidOnSuccess:^{
        STRONG(self);
        STPShippingAddressViewController *addressViewController = [[STPShippingAddressViewController alloc] initWithPaymentContext:self];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addressViewController];
        [navigationController.navigationBar stp_setTheme:self.theme];
        navigationController.modalPresentationStyle = self.modalPresentationStyle;
        [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
    }];
}

- (void)pushShippingInfoViewController {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushShippingInfoViewController on it. Next time, set the hostViewController property first!");
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
        STPShippingAddressViewController *addressViewController = [[STPShippingAddressViewController alloc] initWithPaymentContext:self];
        [navigationController pushViewController:addressViewController animated:YES];
    }];
}

- (void)shippingAddressViewControllerDidCancel:(STPShippingAddressViewController *)addressViewController {
    [self appropriatelyDismissViewController:addressViewController completion:nil];
}

- (void)shippingAddressViewController:(__unused STPShippingAddressViewController *)addressViewController
                      didEnterAddress:(STPAddress *)address
                           completion:(STPShippingMethodsCompletionBlock)completion {
    if ([self.delegate respondsToSelector:@selector(paymentContext:didUpdateShippingAddress:completion:)]) {
        [self.delegate paymentContext:self didUpdateShippingAddress:address completion:^(NSError *shippingValidationError, NSArray<STPShippingMethod *> * shippingMethods) {
            self.shippingMethods = shippingMethods;
            if (completion) {
                completion(shippingValidationError, shippingMethods);
            }
        }];
    }
    else {
        if (completion) {
            completion(nil, @[]);
        }
    }
}

- (void)shippingAddressViewController:(STPShippingAddressViewController *)addressViewController
                 didFinishWithAddress:(STPAddress *)address
                       shippingMethod:(STPShippingMethod *)method {
    self.shippingAddress = address;
    self.selectedShippingMethod = method;
    [self.delegate paymentContextDidChange:self];
    [self appropriatelyDismissViewController:addressViewController completion:^{
        if (addressViewController.isMidPaymentRequest) {
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
        if (!self.selectedPaymentMethod) {
            STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
            addCardViewController.delegate = self;
            addCardViewController.prefilledInformation = self.prefilledInformation;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addCardViewController];
            [navigationController.navigationBar stp_setTheme:self.theme];
            navigationController.modalPresentationStyle = self.modalPresentationStyle;
            [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
        }
        if (self.configuration.requiredShippingAddressFields != STPBillingAddressFieldsNone &&
            !self.shippingAddress)
        {
            STPShippingAddressViewController *addressViewController = [[STPShippingAddressViewController alloc] initWithPaymentContext:self];
            addressViewController.isMidPaymentRequest = YES;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addressViewController];
            [navigationController.navigationBar stp_setTheme:self.theme];
            navigationController.modalPresentationStyle = self.modalPresentationStyle;
            [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
        }
        else if ([self.selectedPaymentMethod isKindOfClass:[STPCard class]]) {
            STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:(STPCard *)self.selectedPaymentMethod];
            [self.delegate paymentContext:self didCreatePaymentResult:result completion:^(NSError * _Nullable error) {
                if (error) {
                    [self.delegate paymentContext:self didFinishWithStatus:STPPaymentStatusError error:error];
                } else {
                    [self.delegate paymentContext:self didFinishWithStatus:STPPaymentStatusSuccess error:nil];
                }
            }];
        }
        else if ([self.selectedPaymentMethod isKindOfClass:[STPApplePayPaymentMethod class]]) {
            PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
            STPApplePayTokenHandlerBlock applePayTokenHandler = ^(STPToken *token, STPErrorBlock tokenCompletion) {
                [self.apiAdapter attachSourceToCustomer:token completion:^(NSError *tokenError) {
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
                }];
            };
            STPShippingMethodSelectionBlock shippingMethodHandler = ^(PKShippingMethod *shippingMethod, STPPaymentSummaryItemCompletionBlock completion) {
                self.selectedShippingMethod = [[STPShippingMethod alloc] initWithPKShippingMethod:shippingMethod currency:self.paymentCurrency];
                [self.delegate paymentContextDidChange:self];
                completion(self.paymentSummaryItems);
            };
            PKPaymentAuthorizationViewController *paymentAuthVC;
            paymentAuthVC = [PKPaymentAuthorizationViewController
                             stp_controllerWithPaymentRequest:paymentRequest
                                                    apiClient:self.apiClient
                                              onTokenCreation:applePayTokenHandler
                                     onShippingMethodSelection:shippingMethodHandler
                                                     onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
                                                         [self.hostViewController dismissViewControllerAnimated:YES completion:^{
                                                             [self.delegate paymentContext:self
                                                                           didFinishWithStatus:status
                                                                                         error:error];
                                                         }];
                                                     }];
            [self.hostViewController presentViewController:paymentAuthVC
                                                      animated:YES
                                                    completion:nil];
        }
    }]onFailure:^(NSError *error) {
        STRONG(self);
        [self.delegate paymentContext:self didFinishWithStatus:STPPaymentStatusError error:error];
    }];
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
    paymentRequest.requiredShippingAddressFields = [STPAddress applePayAddressFieldsFromBillingAddressFields:self.configuration.requiredShippingAddressFields];
    paymentRequest.currencyCode = self.paymentCurrency.uppercaseString;
    paymentRequest.shippingMethods = [STPShippingMethod pkShippingMethods:self.shippingMethods
                                                           selectedMethod:self.selectedShippingMethod];
    return paymentRequest;
}

static char kSTPPaymentCoordinatorAssociatedObjectKey;

- (void)artificiallyRetain:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    [self.hostViewController dismissViewControllerAnimated:YES completion:^{
        [self.delegate paymentContext:self
                  didFinishWithStatus:STPPaymentStatusUserCancellation
                                error:nil];
    }];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion {
    [self.apiAdapter attachSourceToCustomer:token completion:^(NSError *error) {
        if (error) {
            completion(error);
        } else {
            [self.hostViewController dismissViewControllerAnimated:YES completion:^{
                completion(nil);
                self.selectedPaymentMethod = token.card;
                [self requestPayment];
            }];
        }
    }];
}

@end


