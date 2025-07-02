//
//  ShippingManager.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/22/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "ShippingManager.h"
#import <PassKit/PassKit.h>

@implementation ShippingManager

- (NSArray *)defaultShippingMethods {
    return [self californiaShippingMethods];
}

- (void)fetchShippingCostsForAddress:(CNPostalAddress *)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion {
    // you could, for example, go to UPS here and calculate shipping costs to that address.
    if ([address.state isEqualToString:@"CA"]) {
        completion([self californiaShippingMethods], nil);
    } else {
        completion([self internationalShippingMethods], nil);
    }
}

- (NSArray *)californiaShippingMethods {
    PKShippingMethod *upsGround = [[PKShippingMethod alloc] init];
    upsGround.amount = [NSDecimalNumber decimalNumberWithString:@"0.00"];
    upsGround.label = @"UPS Ground";
    upsGround.detail = @"Arrives in 3-5 days";
    upsGround.identifier = @"ups_ground";
    PKShippingMethod *fedex = [[PKShippingMethod alloc] init];
    fedex.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    fedex.label = @"FedEx";
    fedex.detail = @"Arrives tomorrow";
    fedex.identifier = @"fedex";
    return @[upsGround, fedex];
}

- (NSArray *)internationalShippingMethods {
    PKShippingMethod *upsWorldwide = [[PKShippingMethod alloc] init];
    upsWorldwide.amount = [NSDecimalNumber decimalNumberWithString:@"10.99"];
    upsWorldwide.label = @"UPS Worldwide Express";
    upsWorldwide.detail = @"Arrives in 1-3 days";
    upsWorldwide.identifier = @"ups_worldwide";
    return [[self californiaShippingMethods] arrayByAddingObject:upsWorldwide];;
}

@end
