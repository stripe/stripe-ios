//
//  STPPaymentContext.m
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import <objc/runtime.h>
#import "Stripe+ApplePay.h"
#import "NSDecimalNumber+Stripe_Currency.h"
#import "PKPaymentAuthorizationViewController+Stripe_Blocks.h"
#import "NSBundle+Stripe_AppName.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "STPPaymentContext.h"
#import "STPApplePayPaymentMethod.h"
#import "STPPromise.h"
#import "STPCardTuple.h"
#import "STPPaymentMethodTuple.h"
#import "STPPaymentContext+Private.h"
#import "UIViewController+Stripe_Promises.h"
#import "UIViewController+Stripe_Alerts.h"
#import "UINavigationController+Stripe_Completion.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPPaymentContext()<STPPaymentMethodsViewControllerDelegate>

@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPPromise<STPPaymentMethodTuple *> *loadingPromise;
@property(nonatomic)STPVoidPromise *didAppearPromise;
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;

@end

@implementation STPPaymentContext

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                     configuration:(STPPaymentConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _apiAdapter = apiAdapter;
        _didAppearPromise = [STPVoidPromise new];
        _apiClient = [[STPAPIClient alloc] initWithPublishableKey:configuration.publishableKey];
        _paymentCurrency = @"USD";
        __weak typeof(self) weakself = self;
        _loadingPromise = [[[STPPromise<STPPaymentMethodTuple *> new] onSuccess:^(STPPaymentMethodTuple *tuple) {
            weakself.paymentMethods = tuple.paymentMethods;
            weakself.selectedPaymentMethod = tuple.selectedPaymentMethod;
            [weakself.delegate paymentContextDidFinishLoading:weakself];
        }] onFailure:^(NSError * _Nonnull error) {
            [weakself.didAppearPromise onSuccess:^(__unused id value) {
                [weakself.delegate paymentContext:weakself didFailToLoadWithError:error];
            }];
        }];
        [self.apiAdapter retrieveCustomerCards:^(STPCard * _Nullable selectedCard, NSArray<STPCard *> * _Nullable cards, NSError * _Nullable error) {
            if (!weakself) {
                return;
            }
            if (error) {
                [weakself.loadingPromise fail:error];
                return;
            }
            STPCardTuple *tuple = [STPCardTuple tupleWithSelectedCard:selectedCard cards:cards];
            STPPaymentMethodTuple *paymentTuple = [STPPaymentMethodTuple tupleWithCardTuple:tuple applePayEnabled:weakself.configuration.applePayEnabled];
            [weakself.loadingPromise succeed:paymentTuple];
        }];
    }
    return self;
}

- (void)setHostViewController:(UIViewController *)hostViewController {
    NSCAssert(_hostViewController == nil, @"You cannot change the hostViewController on an STPPaymentContext after it's already been set.");
    _hostViewController = hostViewController;
    [self artificiallyRetain:hostViewController];
    [self.didAppearPromise voidCompleteWith:hostViewController.stp_didAppearPromise];
}

- (STPPromise<STPPaymentMethodTuple *> *)currentValuePromise {
    __weak typeof(self) weakself = self;
    return (STPPromise<STPPaymentMethodTuple *> *)[self.loadingPromise map:^id _Nonnull(__unused STPPaymentMethodTuple *value) {
        return [STPPaymentMethodTuple tupleWithPaymentMethods:weakself.paymentMethods selectedPaymentMethod:weakself.selectedPaymentMethod];
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

- (void)presentPaymentMethodsViewController {
    NSCAssert(self.hostViewController != nil, @"hostViewController must not be nil on STPPaymentContext when calling pushPaymentMethodsViewController on it. Next time, set the hostViewController property first!");
    __weak typeof(self)weakself = self;
    [self.didAppearPromise voidOnSuccess:^{
        STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:weakself];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsViewController];
        [navigationController.navigationBar stp_setTheme:weakself.configuration.theme];
        [weakself.hostViewController presentViewController:navigationController animated:YES completion:nil];
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
    __weak typeof(self) weakself = self;
    [weakself.didAppearPromise voidOnSuccess:^{
        STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:weakself];
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

- (void)paymentMethodsViewController:(STPPaymentMethodsViewController *)paymentMethodsViewController
              didFailToLoadWithError:(__unused NSError *)error {
    [self appropriatelyDismissPaymentMethodsViewController:paymentMethodsViewController completion:^{
        STPAlertTuple *tuple = [STPAlertTuple tupleWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:STPAlertStyleDefault
                                                      action:nil];
        [self.hostViewController stp_showAlertWithTitle:NSLocalizedString(@"Error loading payment methods", nil)
                                                message:NSLocalizedString(@"Please try again", nil)
                                                 tuples:@[tuple]];
    }];
}

- (void)appropriatelyDismissPaymentMethodsViewController:(STPPaymentMethodsViewController *)viewController
                                              completion:(STPVoidBlock)completion {
    if ([viewController stp_isRootViewControllerOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [viewController.presentingViewController dismissViewControllerAnimated:YES completion:completion];
    } else {
        // otherwise, we've been pushed onto the stack.
        UIViewController *previousViewController = [viewController stp_previousViewControllerInNavigation];
        [viewController.navigationController stp_popToViewController:previousViewController animated:YES completion:completion];
    }
}

- (BOOL)isReadyForPayment {
    return self.selectedPaymentMethod != nil;
}

- (void)requestPaymentWithResultHandler:(STPPaymentResultHandlerBlock)resultHandler
                             completion:(STPPaymentCompletionBlock)completion {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    __weak typeof(self) weakSelf = self;
    [[self.didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
        return weakSelf.loadingPromise;
    }] onSuccess:^(__unused STPPaymentMethodTuple *tuple) {
        if (!weakSelf) {
            return;
        }
        if (!weakSelf.selectedPaymentMethod) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"No payment method was selected.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please select a payment method and try again.", nil),
                                       };
            NSError *error = [NSError errorWithDomain:StripeDomain
                                                 code:STPInvalidRequestError
                                             userInfo:userInfo];
            completion(STPPaymentStatusError, error);
        }
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPCard class]]) {
            STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:(STPCard *)weakSelf.selectedPaymentMethod];
            resultHandler(result, ^(NSError *error) {
                if (error) {
                    completion(STPPaymentStatusError, error);
                } else {
                    completion(STPPaymentStatusSuccess, nil);
                }
            });
        }
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPApplePayPaymentMethod class]]) {
            PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
            STPApplePayTokenHandlerBlock applePayTokenHandler = ^(STPToken *token, STPErrorBlock tokenCompletion) {
                [weakSelf.apiAdapter attachSourceToCustomer:token.card completion:^(NSError *tokenError) {
                    if (tokenError) {
                        tokenCompletion(tokenError);
                    } else {
                        STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:token.card];
                        resultHandler(result, ^(NSError *error) {
                            if (error) {
                                completion(STPPaymentStatusError, error);
                            } else {
                                completion(STPPaymentStatusSuccess, nil);
                            }
                        });
                    }
                }];
            };
            PKPaymentAuthorizationViewController *paymentAuthViewController = [PKPaymentAuthorizationViewController stp_controllerWithPaymentRequest:paymentRequest apiClient:weakSelf.apiClient
                                                                                                                                     onTokenCreation:applePayTokenHandler
                                                                                                                                            onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
                                                                                                                                                [weakSelf.hostViewController dismissViewControllerAnimated:YES completion:^{
                                                                                                                                                    completion(status, error);
                                                                                                                                                }];
                                                                                                                                            }];
            [weakSelf.hostViewController presentViewController:paymentAuthViewController
                                                      animated:YES
                                                    completion:nil];
        }
    }];
}

- (PKPaymentRequest *)buildPaymentRequest {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    if (!self.configuration.appleMerchantIdentifier || !self.paymentAmount) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.configuration.appleMerchantIdentifier];
    NSDecimalNumber *amount = [NSDecimalNumber stp_decimalNumberWithAmount:self.paymentAmount
                                                                  currency:self.paymentCurrency];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:self.configuration.companyName
                                                                          amount:amount];
    paymentRequest.paymentSummaryItems = @[totalItem];
    paymentRequest.requiredBillingAddressFields = [STPAddress applePayAddressFieldsFromBillingAddressFields:self.configuration.requiredBillingAddressFields];
    return paymentRequest;
}

static char kSTPPaymentCoordinatorAssociatedObjectKey;

- (void)artificiallyRetain:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
