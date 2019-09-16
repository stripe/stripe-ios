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

@property (nonatomic, copy, readwrite) NSString *stripeID;
@property (nonatomic, strong, nullable, readwrite) id<STPSourceProtocol> defaultSource;
@property (nonatomic, strong, readwrite) NSArray<id<STPSourceProtocol>> *sources;
@property (nonatomic, strong, nullable, readwrite) STPAddress *shippingAddress;
@property (nonatomic, copy, readwrite) NSDictionary *allResponseFields;

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

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    // required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    if (!stripeId) {
        return nil;
    }

    STPCustomer *customer = [[self class] new];
    customer.stripeID = stripeId;
    NSDictionary *shippingDict = [dict stp_dictionaryForKey:@"shipping"];
    if (shippingDict) {
        NSDictionary *addressDict = [shippingDict stp_dictionaryForKey:@"address"];
        STPAddress *shipping = [STPAddress decodedObjectFromAPIResponse:addressDict] ?: [STPAddress new];
        shipping.name = [shippingDict stp_stringForKey:@"name"];
        shipping.phone = [shippingDict stp_stringForKey:@"phone"];
        customer.shippingAddress = shipping;
    }
    customer.sources = @[];
    customer.defaultSource = nil;
    customer.allResponseFields = dict;
    [customer updateSourcesFilteringApplePay:YES];
    return customer;
}

- (void)updateSourcesFilteringApplePay:(BOOL)filterApplePay {
    NSDictionary *response = self.allResponseFields;
    NSArray *data;
    NSDictionary *sourcesDict = [response stp_dictionaryForKey:@"sources"];
    if (sourcesDict) {
        data = [sourcesDict stp_arrayForKey:@"data"];
    }
    if (!data) {
        return;
    }
    self.defaultSource = nil;
    NSString *defaultSourceId = [response stp_stringForKey:@"default_source"];
    NSMutableArray *sources = [NSMutableArray new];
    for (id contents in data) {
        if ([contents isKindOfClass:[NSDictionary class]]) {
            NSString *object = [contents stp_stringForKey:@"object"];
            if ([object isEqualToString:@"card"]) {
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
            } else if ([object isEqualToString:@"source"]) {
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
