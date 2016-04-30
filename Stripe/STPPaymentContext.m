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
#import "STPCardPaymentMethod.h"
#import "STPApplePayPaymentMethod.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPPromise.h"
#import "UIFont+Stripe.h"
#import "UIColor+Stripe.h"

@interface STPCardTuple : NSObject
@property(nonatomic)STPCard *selectedCard;
@property(nonatomic)NSArray<STPCard *> *cards;
@end

@implementation STPCardTuple
@end

@interface STPPaymentContext()<STPPaymentMethodsViewControllerDelegate>

@property(nonatomic)id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPPaymentMethodType supportedPaymentMethods;
@property(nonatomic, readwrite, getter=isLoading)BOOL loading;
@property(nonatomic)STPPromise<STPCardTuple *> *initialLoadingPromise;
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;

@end

@implementation STPPaymentContext

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter {
    return [self initWithAPIAdapter:apiAdapter
                          apiClient:[STPAPIClient sharedClient]
            supportedPaymentMethods:STPPaymentMethodTypeAll];
}

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                         apiClient:(STPAPIClient *)apiClient
           supportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods {
    self = [super init];
    if (self) {
        _apiAdapter = apiAdapter;
        _apiClient = apiClient;
        _supportedPaymentMethods = supportedPaymentMethods;
        _paymentCurrency = @"USD";
        _merchantName = [NSBundle stp_applicationName];
        __weak typeof(self) weakSelf = self;
        _initialLoadingPromise = [[[STPPromise<STPCardTuple *> new] onSuccess:^(STPCardTuple *tuple) {
            weakSelf.paymentMethods = [weakSelf parsePaymentMethods:tuple.cards];
            if (tuple.selectedCard) {
                weakSelf.selectedPaymentMethod = [[STPCardPaymentMethod alloc] initWithCard:tuple.selectedCard];
            } else if ([self applePaySupported]) {
                weakSelf.selectedPaymentMethod = [STPApplePayPaymentMethod new];
            }
        }] onFailure:^(NSError * _Nonnull error) {
            [weakSelf.delegate paymentContext:weakSelf didFailToLoadWithError:error];
        }];
    }
    return self;
}

- (void)didAppear {
    [self performInitialLoad];
}

- (void)performInitialLoad {
    if (self.loading || self.initialLoadingPromise.completed) {
        return;
    }
    self.loading = YES;
    [self.apiAdapter retrieveCards:^(STPCard * _Nullable selectedCard, NSArray<STPCard *> * _Nullable cards, NSError * _Nullable error) {
        self.loading = NO;
        if (error) {
            [self.initialLoadingPromise fail:error];
            return;
        }
        STPCardTuple *tuple = [STPCardTuple new];
        tuple.cards = cards;
        tuple.selectedCard = selectedCard;
        [self.initialLoadingPromise succeed:tuple];
    }];
}

- (NSArray<id<STPPaymentMethod>> *)parsePaymentMethods:(NSArray<STPCard *> *)cards {
    NSMutableArray *paymentMethods = [NSMutableArray array];
    for (STPCard *card in cards) {
        [paymentMethods addObject:[[STPCardPaymentMethod alloc] initWithCard:card]];
    }
    if ([self applePaySupported]) {
        [paymentMethods addObject:[STPApplePayPaymentMethod new]];
    }
    return paymentMethods;
}

- (void)onSuccess:(STPVoidBlock)completion {
    [self performInitialLoad];
    [self.initialLoadingPromise onSuccess:^(__unused STPCardTuple *value) {
        completion();
    }];
}

- (void)addToken:(STPToken *)token completion:(STPAddTokenBlock)completion {
    __weak typeof(self) weakSelf = self;
    [self.apiAdapter addToken:token completion:^(STPCard * _Nullable selectedCard, NSArray<STPCard *> * _Nullable cards, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        weakSelf.paymentMethods = [weakSelf parsePaymentMethods:cards];
        if (selectedCard) {
            [weakSelf selectPaymentMethod:[[STPCardPaymentMethod alloc] initWithCard:selectedCard]];
        }
        completion(weakSelf.selectedPaymentMethod, nil);
    }];
}

- (void)selectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    self.selectedPaymentMethod = paymentMethod;
    if (paymentMethod && ![self.paymentMethods containsObject:paymentMethod]) {
        self.paymentMethods = [self.paymentMethods arrayByAddingObject:paymentMethod];
    }
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    if (loading) {
        [self.delegate paymentContextDidBeginLoading:self];
    }
    else {
        [self.delegate paymentContextDidEndLoading:self];
    }
}

- (void)setPaymentMethods:(NSArray<id<STPPaymentMethod>> *)paymentMethods {
    _paymentMethods = [paymentMethods sortedArrayUsingComparator:^NSComparisonResult(id<STPPaymentMethod> obj1, id<STPPaymentMethod> obj2) {
        Class applePayKlass = [STPApplePayPaymentMethod class];
        Class cardKlass = [STPCardPaymentMethod class];
        if ([obj1 isKindOfClass:applePayKlass]) {
            return NSOrderedAscending;
        } else if ([obj2 isKindOfClass:applePayKlass]) {
            return NSOrderedDescending;
        }
        if ([obj1 isKindOfClass:cardKlass] && [obj2 isKindOfClass:cardKlass]) {
            return [[((STPCardPaymentMethod *)obj1).card label]
                    compare:[((STPCardPaymentMethod *)obj2).card label]];
        }
        return NSOrderedSame;
    }];
}

- (void)setSelectedPaymentMethod:(id<STPPaymentMethod>)selectedPaymentMethod {
    if (![_selectedPaymentMethod isEqual:selectedPaymentMethod]) {
        _selectedPaymentMethod = selectedPaymentMethod;
        [self.delegate paymentContextDidChange:self];
    }
}

- (void)presentPaymentMethodsViewControllerOnViewController:(UIViewController *)viewController {
    STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:self delegate:self];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsViewController];
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)pushPaymentMethodsViewControllerOntoNavigationController:(UINavigationController *)navigationController {
    STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentContext:self delegate:self];
    [navigationController pushViewController:paymentMethodsViewController animated:YES];
}

- (void)paymentMethodsViewController:(STPPaymentMethodsViewController *)paymentMethodsViewController
              didSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    self.selectedPaymentMethod = paymentMethod;
    [self appropriatelyDismissPaymentMethodsViewController:paymentMethodsViewController];
}

- (void)paymentMethodsViewControllerDidCancel:(STPPaymentMethodsViewController *)paymentMethodsViewController {
    [self appropriatelyDismissPaymentMethodsViewController:paymentMethodsViewController];
}

- (void)appropriatelyDismissPaymentMethodsViewController:(STPPaymentMethodsViewController *)viewController {
    if ([viewController stp_isRootViewControllerOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        // otherwise, we've been pushed onto the stack.
        UIViewController *previousViewController = [viewController stp_previousViewControllerInNavigation];
        [viewController.navigationController popToViewController:previousViewController animated:YES];
    }
}

- (BOOL)isReadyForPayment {
    return self.selectedPaymentMethod != nil;
}

- (void)requestPaymentFromViewController:(UIViewController *)fromViewController
                           sourceHandler:(STPSourceHandlerBlock)sourceHandler
                              completion:(STPPaymentCompletionBlock)completion {
    [self artificiallyRetain:fromViewController];
    [self performInitialLoad];
    __weak typeof(self) weakSelf = self;
    [self.initialLoadingPromise onSuccess:^(__unused STPCardTuple *tuple) {
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
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPCardPaymentMethod class]]) {
            STPCardPaymentMethod *cardPaymentMethod = (STPCardPaymentMethod *)weakSelf.selectedPaymentMethod;
            [self.apiAdapter selectCard:cardPaymentMethod.card completion:^(STPCard *selectedCard, __unused NSArray<STPCard *> *cards, NSError *cardError) {
                if (cardError) {
                    completion(STPPaymentStatusError, cardError);
                    [weakSelf artificiallyRelease:fromViewController];
                    return;
                }
                sourceHandler(STPPaymentMethodTypeCard, selectedCard, ^(NSError *error) {
                    if (error) {
                        completion(STPPaymentStatusError, error);
                    } else {
                        completion(STPPaymentStatusSuccess, nil);
                    }
                    [weakSelf artificiallyRelease:fromViewController];
                });
            }];
        }
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPApplePayPaymentMethod class]]) {
            PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
            PKPaymentAuthorizationViewController *paymentAuthViewController = [PKPaymentAuthorizationViewController stp_controllerWithPaymentRequest:paymentRequest apiClient:weakSelf.apiClient
                                                                                                                                     onTokenCreation:sourceHandler
                                                                                                                                            onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
                                                                                                                                                [fromViewController dismissViewControllerAnimated:YES completion:^{
                                                                                                                                                    completion(status, error);
                                                                                                                                                    [weakSelf artificiallyRelease:fromViewController];
                                                                                                                                                }];
                                                                                                                                            }];
            [fromViewController presentViewController:paymentAuthViewController
                                             animated:YES
                                           completion:nil];
        }
    }];
}

- (BOOL)applePaySupported {
    return (self.supportedPaymentMethods & STPPaymentMethodTypeApplePay) &&
        [Stripe canSubmitPaymentRequest:[self buildPaymentRequest]];
}

- (PKPaymentRequest *)buildPaymentRequest {
    if (!self.appleMerchantIdentifier || !self.paymentAmount) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.appleMerchantIdentifier];
    NSDecimalNumber *amount = [NSDecimalNumber stp_decimalNumberWithAmount:self.paymentAmount
                                                                  currency:self.paymentCurrency];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:self.merchantName
                                                                          amount:amount];
    paymentRequest.paymentSummaryItems = @[totalItem];
    paymentRequest.requiredBillingAddressFields = [STPAddress applePayAddressFieldsFromBillingAddressFields:self.requiredBillingAddressFields];
    return paymentRequest;
}

static char kSTPPaymentCoordinatorAssociatedObjectKey;

- (void)artificiallyRetain:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)artificiallyRelease:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
