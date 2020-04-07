//
//  STPCustomerContext.m
//  Stripe
//
//  Created by Ben Guo on 5/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCustomerContext.h"
#import "STPCustomerContext+Private.h"

#import "STPAnalyticsClient.h"
#import "STPAPIClient+Private.h"
#import "STPCustomer+Private.h"
#import "STPEphemeralKey.h"
#import "STPEphemeralKeyManager.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodCard.h"
#import "STPPaymentMethodCardWallet.h"
#import "STPDispatchFunctions.h"

/// Stores the key we use in NSUserDefaults to save a dictionary of Customer id to their last selected payment method ID
static NSString *const kLastSelectedPaymentMethodDefaultsKey = @"com.stripe.lib:STPStripeCustomerToLastSelectedPaymentMethodKey";

static NSTimeInterval const CachedCustomerMaxAge = 60;

@interface STPCustomerContext ()

@property (nonatomic) STPCustomer *customer;
@property (nonatomic) NSDate *customerRetrievedDate;
@property (nonatomic, copy) NSArray<STPPaymentMethod *> *paymentMethods;
@property (nonatomic) NSDate *paymentMethodsRetrievedDate;
@property (nonatomic) STPEphemeralKeyManager *keyManager;
@property (nonatomic) STPAPIClient *apiClient;

@end

@implementation STPCustomerContext
@synthesize paymentMethods=_paymentMethods;

+ (void)initialize{
    [[STPAnalyticsClient sharedClient] addClassToProductUsageIfNecessary:[self class]];
}

- (instancetype)initWithKeyProvider:(nonnull id<STPCustomerEphemeralKeyProvider>)keyProvider {
    return [self initWithKeyProvider:keyProvider apiClient:[STPAPIClient sharedClient]];
}

- (instancetype)initWithKeyProvider:(id<STPCustomerEphemeralKeyProvider>)keyProvider apiClient:(STPAPIClient *)apiClient {
    STPEphemeralKeyManager *keyManager = [[STPEphemeralKeyManager alloc] initWithKeyProvider:keyProvider

                                                                                  apiVersion:[STPAPIClient apiVersion] performsEagerFetching:YES];
    return [self initWithKeyManager:keyManager apiClient:apiClient];
}

- (instancetype)initWithKeyManager:(nonnull STPEphemeralKeyManager *)keyManager apiClient:(STPAPIClient *)apiClient {
    self = [self init];
    if (self) {
        _keyManager = keyManager;
        _includeApplePayPaymentMethods = NO;
        _apiClient = apiClient;
        [self retrieveCustomer:nil];
        [self listPaymentMethodsForCustomerWithCompletion:nil];
    }
    return self;
}

- (void)clearCache {
    [self clearCachedCustomer];
    [self clearCachedPaymentMethods];
}

- (void)clearCachedCustomer {
    self.customer = nil;
}

- (void)clearCachedPaymentMethods {
    self.paymentMethods = nil;
}

- (void)setCustomer:(STPCustomer *)customer {
    _customer = customer;
    _customerRetrievedDate = (customer) ? [NSDate date] : nil;
}

- (void)setPaymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods {
    _paymentMethods = [paymentMethods copy];
    _paymentMethodsRetrievedDate = paymentMethods ? [NSDate date] : nil;
}

- (NSArray<STPPaymentMethod *> *)paymentMethods {
    if (!self.includeApplePayPaymentMethods) {
        NSMutableArray<STPPaymentMethod *> *paymentMethodsExcludingApplePay = [NSMutableArray new];
        for (STPPaymentMethod *paymentMethod in _paymentMethods) {
            BOOL isApplePay = paymentMethod.type == STPPaymentMethodTypeCard && paymentMethod.card.wallet.type == STPPaymentMethodCardWalletTypeApplePay;
            if (!isApplePay) {
                [paymentMethodsExcludingApplePay addObject:paymentMethod];
            }
        }
        return paymentMethodsExcludingApplePay;
    } else {
         return _paymentMethods;
    }
}

- (void)setIncludeApplePayPaymentMethods:(BOOL)includeApplePayMethods {
    _includeApplePayPaymentMethods = includeApplePayMethods;
    [self.customer updateSourcesFilteringApplePay:!includeApplePayMethods];
}

- (BOOL)shouldUseCachedCustomer {
    if (!self.customer || !self.customerRetrievedDate) {
        return NO;
    }
    NSDate *now = [NSDate date];
    return [now timeIntervalSinceDate:self.customerRetrievedDate] < CachedCustomerMaxAge;
}

- (BOOL)shouldUseCachedPaymentMethods {
    if (!self.paymentMethods || !self.paymentMethodsRetrievedDate) {
        return NO;
    }
    NSDate *now = [NSDate date];
    return [now timeIntervalSinceDate:self.paymentMethodsRetrievedDate] < CachedCustomerMaxAge;
}

#pragma mark - STPBackendAPIAdapter

- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {
    if ([self shouldUseCachedCustomer]) {
        if (completion) {
            stpDispatchToMainThreadIfNecessary(^{
                completion(self.customer, nil);
            });
        }
        return;
    }
    [self.keyManager getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(nil, retrieveKeyError);
                });
            }
            return;
        }
        [self.apiClient retrieveCustomerUsingKey:ephemeralKey completion:^(STPCustomer *customer, NSError *error) {
            if (customer) {
                [customer updateSourcesFilteringApplePay:!self.includeApplePayPaymentMethods];
                self.customer = customer;
            }
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(customer, error);
                });
            }
        }];
    }];
}

- (void)updateCustomerWithShippingAddress:(STPAddress *)shipping completion:(STPErrorBlock)completion {
    [self.keyManager getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(retrieveKeyError);
                });
            }
            return;
        }
        NSMutableDictionary *params = [NSMutableDictionary new];
        params[@"shipping"] = [STPAddress shippingInfoForChargeWithAddress:shipping
                                                            shippingMethod:nil];
        [self.apiClient updateCustomerWithParameters:[params copy]
                                          usingKey:ephemeralKey
                                        completion:^(STPCustomer *customer, NSError *error) {
                                            if (customer) {
                                                [customer updateSourcesFilteringApplePay:!self.includeApplePayPaymentMethods];
                                                self.customer = customer;
                                            }
                                            if (completion) {
                                                stpDispatchToMainThreadIfNecessary(^{
                                                    completion(error);
                                                });
                                            }
                                        }];
    }];
}

- (void)attachPaymentMethodToCustomer:(STPPaymentMethod *)paymentMethod completion:(STPErrorBlock)completion {
    [self.keyManager getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(retrieveKeyError);
                });
            }
            return;
        }
        
        [self.apiClient attachPaymentMethod:paymentMethod.stripeId
                       toCustomerUsingKey:ephemeralKey
                               completion:^(NSError *error) {
                                   [self clearCachedPaymentMethods];
                                   if (completion) {
                                       stpDispatchToMainThreadIfNecessary(^{
                                           completion(error);
                                       });
                                   }
                               }];
    }];
}

- (void)detachPaymentMethodFromCustomer:(STPPaymentMethod *)paymentMethod completion:(STPErrorBlock)completion {
    [self.keyManager getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(retrieveKeyError);
                });
            }
            return;
        }
        
        [self.apiClient detachPaymentMethod:paymentMethod.stripeId
                     fromCustomerUsingKey:ephemeralKey
                               completion:^(NSError *error) {
                                   [self clearCachedPaymentMethods];
                                   if (completion) {
                                       stpDispatchToMainThreadIfNecessary(^{
                                           completion(error);
                                       });
                                   }
                               }];
    }];

}

- (void)listPaymentMethodsForCustomerWithCompletion:(STPPaymentMethodsCompletionBlock)completion {
    if ([self shouldUseCachedPaymentMethods]) {
        if (completion) {
            stpDispatchToMainThreadIfNecessary(^{
                completion(self.paymentMethods, nil);
            });
        }
        return;
    }

    [self.keyManager getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(nil, retrieveKeyError);
                });
            }
            return;
        }
        
        [self.apiClient listPaymentMethodsForCustomerUsingKey:ephemeralKey completion:^(NSArray<STPPaymentMethod *> *paymentMethods, NSError *error) {
            if (paymentMethods) {
                self.paymentMethods = paymentMethods;
            }
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(self.paymentMethods, error);
                });
            }
        }];
    }];
}

- (void)saveLastSelectedPaymentMethodIDForCustomer:(NSString *)paymentMethodID completion:(nullable STPErrorBlock)completion {
    [self.keyManager getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(retrieveKeyError);
                });
            }
            return;
        }
        
        NSMutableDictionary<NSString *, NSString *>* customerToDefaultPaymentMethodID = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastSelectedPaymentMethodDefaultsKey] mutableCopy] ?: [NSMutableDictionary new];
        NSString *customerID = ephemeralKey.customerID;
        
        customerToDefaultPaymentMethodID[customerID] = [paymentMethodID copy];
        [[NSUserDefaults standardUserDefaults] setObject:customerToDefaultPaymentMethodID forKey:kLastSelectedPaymentMethodDefaultsKey];
        if (completion) {
            stpDispatchToMainThreadIfNecessary(^{
                completion(nil);
            });
        }
    }];
}

- (void)retrieveLastSelectedPaymentMethodIDForCustomerWithCompletion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    [self.keyManager getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                stpDispatchToMainThreadIfNecessary(^{
                    completion(nil, retrieveKeyError);
                });
            }
            return;
        }
        
        NSDictionary<NSString *, NSString *>* customerToDefaultPaymentMethodID = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastSelectedPaymentMethodDefaultsKey];
        stpDispatchToMainThreadIfNecessary(^{
            completion(customerToDefaultPaymentMethodID[ephemeralKey.customerID], nil);
        });
    }];
}

@end
