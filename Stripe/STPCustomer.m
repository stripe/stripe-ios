//
//  STPCustomer.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCustomer.h"

#import "NSDictionary+Stripe.h"
#import "NSError+Stripe.h"
#import "STPAddress.h"
#import "STPCard.h"
#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCustomer()

@property (nonatomic, copy) NSString *stripeID;
@property (nonatomic) id<STPSourceProtocol> defaultSource;
@property (nonatomic) NSArray<id<STPSourceProtocol>> *sources;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPCustomer

+ (instancetype)customerWithStripeID:(NSString *)stripeID
                       defaultSource:(nullable id<STPSourceProtocol>)defaultSource
                             sources:(NSArray<id<STPSourceProtocol>> *)sources {
    STPCustomer *customer = [self new];
    customer.stripeID = stripeID;
    customer.defaultSource = defaultSource;
    customer.sources = sources;
    return customer;
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"stripeID = %@", self.stripeID],

                       // Sources
                       [NSString stringWithFormat:@"defaultSource = %@", self.defaultSource],
                       [NSString stringWithFormat:@"sources = %@", self.sources],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[@"id"];
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPCustomer *customer = [[self class] new];
    customer.stripeID = dict[@"id"];
    if ([dict[@"shipping"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *shippingDict = dict[@"shipping"];
        STPAddress *shipping = [STPAddress new];
        shipping.name = shippingDict[@"name"];
        shipping.phone = shippingDict[@"phone"];
        shipping.line1 = shippingDict[@"address"][@"line1"];
        shipping.line2 = shippingDict[@"address"][@"line2"];
        shipping.city = shippingDict[@"address"][@"city"];
        shipping.state = shippingDict[@"address"][@"state"];
        shipping.postalCode = shippingDict[@"address"][@"postal_code"];
        shipping.country = shippingDict[@"address"][@"country"];
        customer.shippingAddress = shipping;
    }
    [customer updateSourcesWithResponse:dict filteringApplePay:YES];
    customer.allResponseFields = dict;
    return customer;
}

- (void)updateSourcesWithResponse:(NSDictionary *)response
                filteringApplePay:(BOOL)filterApplePay {
    NSArray *data;
    if ([response[@"sources"] isKindOfClass:[NSDictionary class]]) {
        data = response[@"sources"][@"data"];
    }
    if (![data isKindOfClass:[NSArray class]]) {
        return;
    }
    NSString *defaultSourceId;
    if ([response[@"default_source"] isKindOfClass:[NSString class]]) {
        defaultSourceId = response[@"default_source"];
    }
    NSMutableArray *sources = [NSMutableArray new];
    for (id contents in data) {
        if ([contents isKindOfClass:[NSDictionary class]]) {
            if ([contents[@"object"] isEqualToString:@"card"]) {
                STPCard *card = [STPCard decodedObjectFromAPIResponse:contents];
                BOOL includeCard = card != nil;
                // ignore apple pay cards from the response
                if (filterApplePay && card.isApplePayCard) {
                    includeCard = NO;
                }
                if (includeCard) {
                    [sources addObject:card];
                    if (defaultSourceId && [card.stripeID isEqualToString:defaultSourceId]) {
                        self.defaultSource = card;
                    }
                }
            }
            else if ([contents[@"object"] isEqualToString:@"source"]) {
                STPSource *source = [STPSource decodedObjectFromAPIResponse:contents];
                BOOL includeSource = source != nil;
                // ignore apple pay cards from the response
                if (filterApplePay && (source.type == STPSourceTypeCard &&
                                       source.cardDetails != nil &&
                                       source.cardDetails.isApplePayCard)) {
                    includeSource = NO;
                }
                if (includeSource) {
                    [sources addObject:source];
                    if (defaultSourceId && [source.stripeID isEqualToString:defaultSourceId]) {
                        self.defaultSource = source;
                    }
                }
            }
        }
    }
    self.sources = sources;
}

@end

@interface STPCustomerDeserializer()

@property (nonatomic, nullable) STPCustomer *customer;
@property (nonatomic, nullable) NSError *error;

@end

@implementation STPCustomerDeserializer

- (instancetype)initWithData:(nullable NSData *)data
                 urlResponse:(nullable __unused NSURLResponse *)urlResponse
                       error:(nullable NSError *)error {
    if (error) {
        return [self initWithError:error];
    }

    if (data == nil) {
        return [self initWithError:[NSError stp_genericFailedToParseResponseError]];
    }

    NSError *jsonError;
    id json = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)kNilOptions error:&jsonError];
    if (!json) {
        return [self initWithError:jsonError];
    }
    return [self initWithJSONResponse:json];
}

- (instancetype)initWithError:(NSError *)error {
    self = [super init];
    if (self) {
        _error = error;
    }
    return self;
}

- (instancetype)initWithJSONResponse:(id)json {
    self = [super init];
    if (self) {
        STPCustomer *customer = [STPCustomer decodedObjectFromAPIResponse:json];
        if (!customer) {
            _error = [NSError stp_genericFailedToParseResponseError];
        } else {
            _customer = customer;
        }
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
