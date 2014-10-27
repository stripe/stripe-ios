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

- (void)fetchShippingCostsForAddress:(ABRecordRef)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion {
    // you could, for example, go to UPS here and calculate shipping costs to that address.
    ABMultiValueRef addressValues = ABRecordCopyValue(address, kABPersonAddressProperty);
    NSString *state;
    if (ABMultiValueGetCount(addressValues) > 0) {
        CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
        state = CFDictionaryGetValue(dict, kABPersonAddressStateKey);
        CFRelease(dict);
    }
    if (!state) {
        completion(nil, [NSError new]);
    }
    if ([state isEqualToString:@"CA"]) {
        completion([self californiaShippingMethods], nil);
    } else {
        completion([self internationalShippingMethods], nil);
    }
    CFRelease(addressValues);
}

- (NSArray *)californiaShippingMethods {
    PKShippingMethod *normalItem =
        [PKShippingMethod summaryItemWithLabel:@"Llama California Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"20.00"]];
    normalItem.detail = @"3-5 Business Days";
    normalItem.identifier = normalItem.label;
    PKShippingMethod *expressItem =
        [PKShippingMethod summaryItemWithLabel:@"Llama California Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"30.00"]];
    expressItem.detail = @"Next Day";
    expressItem.identifier = expressItem.label;
    return @[normalItem, expressItem];
}

- (NSArray *)internationalShippingMethods {
    PKShippingMethod *normalItem = [PKShippingMethod summaryItemWithLabel:@"Llama US Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"40.00"]];
    normalItem.detail = @"3-5 Business Days";
    normalItem.identifier = normalItem.label;
    PKShippingMethod *expressItem =
        [PKShippingMethod summaryItemWithLabel:@"Llama US Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"50.00"]];
    expressItem.detail = @"Next Day";
    expressItem.identifier = expressItem.label;
    return @[normalItem, expressItem];
}

@end
