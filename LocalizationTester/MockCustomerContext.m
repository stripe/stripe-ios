//
//  MockCustomerContext.m
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/14/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "MockCustomerContext.h"

#pragma mark -  MockCustomer

@interface MockCustomer: NSObject
@property (nonatomic) NSMutableArray<STPPaymentMethod *> *mockPaymentMethods;
@property (nonatomic) STPPaymentMethod *mockDefaultPaymentMethod;
@property (nonatomic) STPAddress *mockShippingAddress;

@end

@implementation MockCustomer

- (instancetype)init {
    self = [super init];
    if (self) {
        _mockPaymentMethods = [NSMutableArray array];
        /**
         //     Preload the mock customer with saved cards.
         //     last4 values are from test cards: https://stripe.com/docs/testing#cards
         //     Not using the "4242" and "4444" numbers, since those are the easiest
         //     to remember and fill.
         //     */
        NSDictionary *visa = @{ @"card" : @{
                                    @"exp_month": @10,
                                    @"exp_year": @2020,
                                    @"last4": @"1881",
                                    @"brand": @"visa",
                                },
                                @"id": @"preloaded_visa",
                                @"type": @"card",
                                };

        STPPaymentMethod *visaCard = [STPPaymentMethod decodedObjectFromAPIResponse:visa];
        if (visaCard) {
            [_mockPaymentMethods addObject:visaCard];
        }

        NSDictionary *masterCard = @{ @"card" : @{
                                        @"exp_month": @10,
                                        @"exp_year": @2020,
                                        @"last4": @"8210",
                                        @"brand": @"mastercard",
                                        },
                                @"id": @"preloaded_mastercard",
                                @"type": @"card",
                                };
        STPPaymentMethod *masterCardCard = [STPPaymentMethod decodedObjectFromAPIResponse:masterCard];
        if (masterCardCard) {
            [_mockPaymentMethods addObject:masterCardCard];
        }

        NSDictionary *amex = @{ @"card" : @{
                                              @"exp_month": @10,
                                              @"exp_year": @2020,
                                              @"last4": @"0005",
                                              @"brand": @"amex",
                                              },
                                      @"id": @"preloaded_amex",
                                      @"type": @"card",
                                      };
        STPPaymentMethod *amexCard = [STPPaymentMethod decodedObjectFromAPIResponse:amex];
        if (amexCard) {
            [_mockPaymentMethods addObject:amexCard];
        }
    }

    return self;
}

- (NSArray<STPPaymentMethod *> *)paymentMethods {
    return self.mockPaymentMethods;
}

- (STPPaymentMethod *)defaultSource {
    return self.mockDefaultPaymentMethod;
}

- (STPAddress *)shippingAddress {
    return self.mockShippingAddress;
}

@end

#pragma mark - MockCustomerContext

@implementation MockCustomerContext
{
    MockCustomer *_mockCustomer;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _mockCustomer = [[MockCustomer alloc] init];
    }

    return self;
}

- (void)retrieveCustomer:(void (^ _Nullable)(STPCustomer * _Nullable, NSError * _Nullable))completion {
    if (!self.neverRetrieveCustomer) {
        if (completion) {
            completion((STPCustomer *)_mockCustomer, nil);
        }
    }
}

- (void)updateCustomerWithShippingAddress:(STPAddress * _Nonnull)shipping completion:(void (^ _Nullable)(NSError * _Nullable))completion {
    _mockCustomer.mockShippingAddress = shipping;
    if (completion) {
        completion(nil);
    }
}

- (void)listPaymentMethodsForCustomerWithCompletion:(void (^ _Nullable)(NSArray<STPPaymentMethod *> * _Nullable, NSError * _Nullable))completion {
    if (!self.neverRetrieveCustomer) {
        completion(_mockCustomer.mockPaymentMethods, nil);
    }
}

- (void)attachPaymentMethodToCustomer:(STPPaymentMethod * _Nonnull)paymentMethod completion:(void (^ _Nullable)(NSError * _Nullable))completion {
    [_mockCustomer.mockPaymentMethods addObject:paymentMethod];
    if (completion) {
        completion(nil);
    }
}

- (void)detachPaymentMethodFromCustomer:(STPPaymentMethod * _Nonnull)paymentMethod completion:(void (^ _Nullable)(NSError * _Nullable))completion {
    NSUInteger index = [_mockCustomer.mockPaymentMethods indexOfObjectPassingTest:^BOOL(STPPaymentMethod * _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stripeId == paymentMethod.stripeId) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (index != NSNotFound) {
        [_mockCustomer.mockPaymentMethods removeObjectAtIndex:index];
    }
    if (completion) {
        completion(nil);
    }
}

@end
