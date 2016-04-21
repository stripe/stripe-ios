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

@interface STPPaymentContext()

@property(nonatomic)id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic)STPPaymentMethodType supportedPaymentMethods;
@property(nonatomic, readwrite, getter=isLoading)BOOL loading;
@property(nonatomic)STPPromise<STPCardTuple *> *initialLoadingPromise;
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;

@end

@implementation STPPaymentContext

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter supportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods {
    self = [super init];
    if (self) {
        _apiAdapter = apiAdapter;
        _supportedPaymentMethods = supportedPaymentMethods;
        _paymentCurrency = @"USD";
        _merchantName = [NSBundle stp_applicationName];
        __weak typeof(self) weakSelf = self;
        _initialLoadingPromise = [[STPPromise<STPCardTuple *> new] onSuccess:^(STPCardTuple *tuple) {
            weakSelf.paymentMethods = [weakSelf parsePaymentMethods:tuple.cards];
            if (tuple.selectedCard) {
                weakSelf.selectedPaymentMethod = [[STPCardPaymentMethod alloc] initWithCard:tuple.selectedCard];
            } else if ([self applePaySupported]) {
                weakSelf.selectedPaymentMethod = [STPApplePayPaymentMethod new];
            }
        }];
    }
    return self;
}

- (void)performInitialLoad {
    if (self.loading || self.initialLoadingPromise.completed) {
        return;
    }
    self.loading = YES;
    [self.apiAdapter retrieveCards:^(STPCard * _Nullable selectedCard, NSArray<STPCard *> * _Nullable cards, NSError * _Nullable error) {
        self.loading = NO;
        if (error) {
            // TODO surface this error somewhere.
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
    if (![self.paymentMethods containsObject:paymentMethod]) {
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
        [self.delegate paymentContext:self selectedPaymentMethodDidChange:selectedPaymentMethod];
    }
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
            STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithAPIClient:weakSelf.apiClient completion:^(STPToken *token, STPErrorBlock tokenCompletion) {
                if (token) {
                    [weakSelf addToken:token completion:^(id<STPPaymentMethod>  _Nullable paymentMethod, NSError * _Nullable error) {
                        if (error) {
                            tokenCompletion(error);
                        } else {
                            [weakSelf selectPaymentMethod:paymentMethod];
                            [fromViewController dismissViewControllerAnimated:YES completion:^{
                                tokenCompletion(nil);
                                [weakSelf requestPaymentFromViewController:fromViewController sourceHandler:sourceHandler completion:completion];
                            }];
                        }
                    }];
                } else {
                    [fromViewController dismissViewControllerAnimated:YES completion:^{
                        tokenCompletion(nil);
                        completion(STPPaymentStatusUserCancellation, nil);
                    }];
                }
            }];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentCardViewController];
            NSDictionary *titleTextAttributes = @{NSFontAttributeName:[UIFont stp_navigationBarFont]};
            [navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
            [navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                    forBarPosition:UIBarPositionAny
                                                        barMetrics:UIBarMetricsDefault];
            [[UINavigationBar appearance] setShadowImage:[UIImage new]];
            [navigationController.navigationBar setBarTintColor:[UIColor stp_backgroundGreyColor]];
            [fromViewController presentViewController:navigationController animated:YES completion:nil];
        }
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPCardPaymentMethod class]]) {
            STPCardPaymentMethod *cardPaymentMethod = (STPCardPaymentMethod *)weakSelf.selectedPaymentMethod;
            sourceHandler(STPPaymentMethodTypeCard, cardPaymentMethod.card, ^(NSError *error) {
                if (error) {
                    completion(STPPaymentStatusError, error);
                } else {
                    completion(STPPaymentStatusSuccess, nil);
                }
                [weakSelf artificiallyRelease:fromViewController];
            });
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
