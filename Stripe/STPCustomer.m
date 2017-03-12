//
//  STPCustomer.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCustomer.h"

#import "STPCard.h"
#import "STPSource.h"
#import "StripeError.h"

@interface STPCustomer()

@property(nonatomic, copy)NSString *stripeID;
@property(nonatomic) id<STPSourceProtocol> defaultSource;
@property(nonatomic) NSArray<id<STPSourceProtocol>> *sources;

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

@end

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
        if (![json isKindOfClass:[NSDictionary class]] || ![json[@"id"] isKindOfClass:[NSString class]]) {
            _error = [NSError stp_genericFailedToParseResponseError];
            return self;
        }
        STPCustomer *customer = [STPCustomer new];
        customer.stripeID = json[@"id"];
        NSString *defaultSourceId;
        if ([json[@"default_source"] isKindOfClass:[NSString class]]) {
            defaultSourceId = json[@"default_source"];
        }
        NSMutableArray *sources = [NSMutableArray array];
        if ([json[@"sources"] isKindOfClass:[NSDictionary class]] && [json[@"sources"][@"data"] isKindOfClass:[NSArray class]]) {
            for (id contents in json[@"sources"][@"data"]) {
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
        _customer = customer;
    }
    return self;
}

@end
