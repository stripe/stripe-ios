//
//  MockCustomerContext.m
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/14/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "MockCustomerContext.h"
#import "STPCustomer+Private.h"

#pragma mark -  MockCustomer

@interface MockCustomer: STPCustomer
@property (nonatomic) NSMutableArray<id<STPSourceProtocol>> *mockSources;
@property (nonatomic) id<STPSourceProtocol> mockDefaultSource;
@property (nonatomic) STPAddress *mockShippingAddress;

@end

@implementation MockCustomer

- (instancetype)init {
    self = [super init];
    if (self) {
        _mockSources = [NSMutableArray array];
        /**
         //     Preload the mock customer with saved cards.
         //     last4 values are from test cards: https://stripe.com/docs/testing#cards
         //     Not using the "4242" and "4444" numbers, since those are the easiest
         //     to remember and fill.
         //     */
        NSDictionary *visa = @{
                                @"id": @"preloaded_visa",
                                @"exp_month": @10,
                                @"exp_year": @2020,
                                @"last4": @"1881",
                                @"brand": @"visa",
                                };

        STPCard *visaCard = [STPCard decodedObjectFromAPIResponse:visa];
        if (visaCard) {
            [_mockSources addObject:visaCard];
        }

        NSDictionary *masterCard = @{
                          @"id": @"preloaded_mastercard",
                          @"exp_month": @10,
                          @"exp_year": @2020,
                          @"last4": @"8210",
                          @"brand": @"mastercard",
                          };
        STPCard *masterCardCard = [STPCard decodedObjectFromAPIResponse:masterCard];
        if (masterCardCard) {
            [_mockSources addObject:masterCardCard];
        }

        NSDictionary *amex = @{
                    @"id": @"preloaded_amex",
                    @"exp_month": @10,
                    @"exp_year": @2020,
                    @"last4": @"0005",
                    @"brand": @"american express",
                    };
        STPCard *amexCard = [STPCard decodedObjectFromAPIResponse:amex];
        if (amexCard) {
            [_mockSources addObject:amexCard];
        }
    }

    return self;
}

- (NSArray<id<STPSourceProtocol>> *)sources {
    return self.mockSources;
}

- (id<STPSourceProtocol>)defaultSource {
    return self.mockDefaultSource;
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

- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {
    if (!self.neverRetrieveCustomer) {
        if (completion) {
            completion(_mockCustomer, nil);
        }
    }
}
- (void)attachSourceToCustomer:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    if ([source isKindOfClass:[STPToken class]] && ((STPToken *)source).card != nil) {
        [_mockCustomer.mockSources addObject:((STPToken *)source).card];
    }
    if (completion) {
        completion(nil);
    }
}

- (void)selectDefaultCustomerSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    BOOL hasSource = [_mockCustomer.sources indexOfObjectPassingTest:^BOOL(id<STPSourceProtocol>  _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stripeID == source.stripeID) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (hasSource) {
        _mockCustomer.mockDefaultSource = source;
    }
    if (completion) {
        completion(nil);
    }
}

- (void)updateCustomerWithShippingAddress:(STPAddress *)shipping completion:(STPErrorBlock)completion {
    _mockCustomer.mockShippingAddress = shipping;
    if (completion) {
        completion(nil);
    }
}

- (void)detachSourceFromCustomer:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    NSUInteger index = [_mockCustomer.sources indexOfObjectPassingTest:^BOOL(id<STPSourceProtocol>  _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stripeID == source.stripeID) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (index != NSNotFound) {
        [_mockCustomer.mockSources removeObjectAtIndex:index];
    }
    if (completion) {
        completion(nil);
    }
}

@end
