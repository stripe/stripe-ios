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

@interface STPPaymentMethodTuple : NSObject
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;
@end

@implementation STPPaymentMethodTuple
@end

@interface STPPaymentContext()

@property(nonatomic)id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic)STPPaymentMethodType supportedPaymentMethods;
@property(nonatomic, readwrite, getter=isLoading)BOOL loading;
@property(nonatomic)STPPromise<STPPaymentMethodTuple *> *initialLoadingPromise;

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
        _initialLoadingPromise = [[STPPromise<STPPaymentMethodTuple *> new] onSuccess:^(STPPaymentMethodTuple *tuple) {
            weakSelf.selectedPaymentMethod = tuple.selectedPaymentMethod;
            NSMutableArray *paymentMethods = [tuple.paymentMethods mutableCopy];
            if ([self applePaySupported]) {
                STPApplePayPaymentMethod *method = [STPApplePayPaymentMethod new];
                [paymentMethods addObject:method];
                weakSelf.selectedPaymentMethod = weakSelf.selectedPaymentMethod ?: method;
            }
            weakSelf.paymentMethods = paymentMethods;
        }];
    }
    return self;
}

- (void)performInitialLoad {
    if (self.loading || self.initialLoadingPromise.completed) {
        return;
    }
    self.loading = YES;
    [self.apiAdapter retrieveSources:^(id<STPSource> selectedSource, NSArray<id<STPSource>> *sources, NSError *error) {
        self.loading = NO;
        if (error) {
            // TODO surface this error somewhere.
            [self.initialLoadingPromise fail:error];
            return;
        }
        STPPaymentMethodTuple *tuple = [STPPaymentMethodTuple new];
        NSMutableArray *paymentMethods = [NSMutableArray array];
        for (id<STPSource> source in sources) {
            [paymentMethods addObject:[[STPCardPaymentMethod alloc] initWithSource:source]];
        }
        tuple.paymentMethods = paymentMethods;
        if (selectedSource) {
            tuple.selectedPaymentMethod = [[STPCardPaymentMethod alloc] initWithSource:selectedSource];
        }
        [self.initialLoadingPromise succeed:tuple];
    }];
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

- (void)setSelectedPaymentMethod:(id<STPPaymentMethod>)selectedPaymentMethod {
    _selectedPaymentMethod = selectedPaymentMethod;
    [self.delegate paymentContext:self selectedPaymentMethodDidChange:selectedPaymentMethod];
}

- (void)requestPaymentFromViewController:(UIViewController *)fromViewController
                           sourceHandler:(STPSourceHandlerBlock)sourceHandler
                              completion:(STPPaymentCompletionBlock)completion {
    [self artificiallyRetain:fromViewController];
    [self performInitialLoad];
    __weak typeof(self) weakSelf = self;
    [self.initialLoadingPromise onSuccess:^(__unused STPPaymentMethodTuple *tuple) {
        if (!weakSelf) {
            return;
        }
        if (!weakSelf.selectedPaymentMethod) {
            STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithAPIClient:weakSelf.apiClient completion:^(id<STPSource> source) {
                [fromViewController dismissViewControllerAnimated:YES completion:^{
                    if (source) {
                        weakSelf.selectedPaymentMethod = [[STPCardPaymentMethod alloc] initWithSource:source];
                        [weakSelf requestPaymentFromViewController:fromViewController sourceHandler:sourceHandler completion:completion];
                    } else {
                        completion(STPPaymentStatusUserCancellation, nil);
                    }
                }];
            }];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentCardViewController];
            NSDictionary *titleTextAttributes = @{NSFontAttributeName:[UIFont stp_navigationBarFont]};
            [navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
            [navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                    forBarPosition:UIBarPositionAny
                                                        barMetrics:UIBarMetricsDefault];
            [[UINavigationBar appearance] setShadowImage:[UIImage new]];
            [navigationController.navigationBar setBarTintColor:[UIColor stp_backgroundColor]];
            [fromViewController presentViewController:navigationController animated:YES completion:nil];
        }
        else if ([weakSelf.selectedPaymentMethod isKindOfClass:[STPCardPaymentMethod class]]) {
            STPCardPaymentMethod *cardPaymentMethod = (STPCardPaymentMethod *)weakSelf.selectedPaymentMethod;
            sourceHandler(STPPaymentMethodTypeCard, cardPaymentMethod.source, ^(NSError *error) {
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
