//
//  STPCustomer.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCustomer.h"

#import "STPAddress.h"
#import "STPCard.h"
#import "STPSource.h"
#import "StripeError.h"
#import "NSDictionary+Stripe.h"

@interface STPCustomer()

@property(nonatomic, copy)NSString *stripeID;
@property(nonatomic) id<STPSourceProtocol> defaultSource;
@property(nonatomic) NSArray<id<STPSourceProtocol>> *sources;
@property(nonatomic) STPAddress *shippingAddress;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPCustomer

+ (instancetype)customerWithStripeID:(NSString *)stripeID
                       defaultSource:(id<STPSourceProtocol>)defaultSource
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

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPCustomer *customer = [[self class] new];
    customer.stripeID = dict[@"id"];
    NSString *defaultSourceId;
    if ([dict[@"default_source"] isKindOfClass:[NSString class]]) {
        defaultSourceId = dict[@"default_source"];
    }
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
    NSMutableArray *sources = [NSMutableArray array];
    if ([dict[@"sources"] isKindOfClass:[NSDictionary class]] && [dict[@"sources"][@"data"] isKindOfClass:[NSArray class]]) {
        for (id contents in dict[@"sources"][@"data"]) {
            if ([contents isKindOfClass:[NSDictionary class]]) {
                // eventually support other source types
                if ([contents[@"object"] isEqualToString:@"card"]) {
                    STPCard *card = [STPCard decodedObjectFromAPIResponse:contents];
                    // ignore apple pay cards from the response
                    if (card && !card.isApplePayCard) {
                        [sources addObject:card];
                        if (defaultSourceId && [card.stripeID isEqualToString:defaultSourceId]) {
                            customer.defaultSource = card;
                        }
                    }
                }
                else if ([contents[@"object"] isEqualToString:@"source"]) {
                    STPSource *source = [STPSource decodedObjectFromAPIResponse:contents];
                    if (source) {
                        [sources addObject:source];
                        if (defaultSourceId && [source.stripeID isEqualToString:defaultSourceId]) {
                            customer.defaultSource = source;
                        }
                    }
                }
            }
        }
        customer.sources = sources;
    }
    customer.allResponseFields = dict;
    return customer;
}

@end

/**
 NOTE: STPCustomerDeserializer has been deprecated. When we remove 
 STPBackendAPIAdapter, we should also remove STPCustomerDeserializer.
 */
@interface STPCustomerDeserializer()

@property(nonatomic, nullable)STPCustomer *customer;
@property(nonatomic, nullable)NSError *error;

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
