//
//  STPPaymentContext.m
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import <objc/runtime.h>
#import "NSDecimalNumber+Stripe_Currency.h"
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

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPPaymentContext()<STPPaymentMethodsViewControllerDelegate, STPAddCardViewControllerDelegate>

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
        [self retryLoading];
    }
    return self;
}

- (void)retryLoading {
    if (self.loadingPromise && self.loadingPromise.value) {
        return;
    }
    __weak typeof(self) weakself = self;
    self.loadingPromise = [[[STPPromise<STPPaymentMethodTuple *> new] onSuccess:^(STPPaymentMethodTuple *tuple) {
        weakself.paymentMethods = tuple.paymentMethods;
        weakself.selectedPaymentMethod = tuple.selectedPaymentMethod;
    }] onFailure:^(NSError * _Nonnull error) {
        if (weakself.hostViewController) {
            [weakself.didAppearPromise onSuccess:^(__unused id value) {
                if (weakself.paymentMethodsViewController) {
                    [weakself appropriatelyDismissPaymentMethodsViewController:weakself.paymentMethodsViewController completion:^{
                        [weakself.delegate paymentContext:weakself didFailToLoadWithError:error];
                    }];
                } else {
                    [weakself.delegate paymentContext:weakself didFailToLoadWithError:error];
                }
            }];
        }
    }];
    [self.apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable error) {
        if (!weakself) {
            return;
        }
        if (error) {
            [weakself.loadingPromise fail:error];
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
        STPPaymentMethodTuple *paymentTuple = [STPPaymentMethodTuple tupleWithCardTuple:tuple applePayEnabled:weakself.configuration.applePayEnabled];
        [weakself.loadingPromise succeed:paymentTuple];
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
    __weak typeof(self) weakself = self;
    [self.willAppearPromise voidOnSuccess:^{
        if (weakself.delegate == delegate) {
            [delegate paymentContextDidChange:weakself];
        }
    }];
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
        weakself.paymentMethodsViewController = paymentMethodsViewController;
        paymentMethodsViewController.prefilledInformation = weakself.prefilledInformation;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsViewController];
        [navigationController.navigationBar stp_setTheme:weakself.theme];
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
    [self.didAppearPromise voidOnSuccess:^{
        STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:weakself];
        weakself.paymentMethodsViewController = paymentMethodsViewController;
        paymentMethodsViewController.prefilledInformation = weakself.prefilledInformation;
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

- (void)requestPayment {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    __weak typeof(self) weakSelf = self;
    [[[self.didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
        return weakSelf.loadingPromise;
    }] onSuccess:^(__unused STPPaymentMethodTuple *tuple) {
        if (!weakSelf) {
            return;
        }
        if (!weakSelf.selectedPaymentMethod) {
            STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
            addCardViewController.delegate = self;
            addCardViewController.prefilledInformation = self.prefilledInformation;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addCardViewController];
            [navigationController.navigationBar stp_setTheme:weakSelf.theme];
            [weakSelf.hostViewController presentViewController:navigationController animated:YES completion:nil];
        }
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPCard class]]) {
            STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:(STPCard *)weakSelf.selectedPaymentMethod];
            [weakSelf.delegate paymentContext:weakSelf didCreatePaymentResult:result completion:^(NSError * _Nullable error) {
                if (error) {
                    [weakSelf.delegate paymentContext:weakSelf didFinishWithStatus:STPPaymentStatusError error:error];
                } else {
                    [weakSelf.delegate paymentContext:weakSelf didFinishWithStatus:STPPaymentStatusSuccess error:nil];
                }
            }];
        }
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPApplePayPaymentMethod class]]) {
            PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
            STPApplePayTokenHandlerBlock applePayTokenHandler = ^(STPToken *token, STPErrorBlock tokenCompletion) {
                [weakSelf.apiAdapter attachSourceToCustomer:token completion:^(NSError *tokenError) {
                    if (tokenError) {
                        tokenCompletion(tokenError);
                    } else {
                        STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:token.card];
                        [weakSelf.delegate paymentContext:weakSelf didCreatePaymentResult:result completion:^(NSError * error) {
                            if (error) {
                                tokenCompletion(error);
                                [weakSelf.delegate paymentContext:weakSelf didFinishWithStatus:STPPaymentStatusError error:error];
                            } else {
                                tokenCompletion(nil);
                                [weakSelf.delegate paymentContext:weakSelf didFinishWithStatus:STPPaymentStatusSuccess error:nil];
                            }
                        }];
                    }
                }];
            };
            PKPaymentAuthorizationViewController *paymentAuthVC;
            paymentAuthVC = [PKPaymentAuthorizationViewController
                             stp_controllerWithPaymentRequest:paymentRequest
                                                    apiClient:weakSelf.apiClient
                                              onTokenCreation:applePayTokenHandler
                                                     onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
                                                         [weakSelf.hostViewController dismissViewControllerAnimated:YES completion:^{
                                                             [weakSelf.delegate paymentContext:weakSelf
                                                                           didFinishWithStatus:status
                                                                                         error:error];
                                                         }];
                                                     }];
            [weakSelf.hostViewController presentViewController:paymentAuthVC
                                                      animated:YES
                                                    completion:nil];
        }
    }]onFailure:^(NSError *error) {
        [weakSelf.delegate paymentContext:weakSelf didFinishWithStatus:STPPaymentStatusError error:error];
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
