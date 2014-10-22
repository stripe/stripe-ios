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
    return [self domesticShippingMethods];
}

- (void)fetchShippingCostsForAddress:(ABRecordRef)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion {
    // you could, for example, go to UPS here and calculate shipping costs to that address.
    ABMultiValueRef addressValues = ABRecordCopyValue(address, kABPersonAddressProperty);
    NSString *country;
    if (ABMultiValueGetCount(addressValues) > 0) {
        CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
        country = CFDictionaryGetValue(dict, kABPersonAddressCountryKey);
    }
    if (!country) {
        completion(nil, [NSError new]);
    }
    if ([country isEqualToString:@"US"]) {
        completion([self domesticShippingMethods], nil);
    } else {
        completion([self internationalShippingMethods], nil);
    }
}

- (NSArray *)domesticShippingMethods {
    PKShippingMethod *normalItem = [PKShippingMethod summaryItemWithLabel:@"Llama Domestic Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"20.00"]];
    normalItem.detail = @"3-5 Business Days";
    PKShippingMethod *expressItem =
        [PKShippingMethod summaryItemWithLabel:@"Llama Domestic Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"30.00"]];
    expressItem.detail = @"Next Day";
    return @[normalItem, expressItem];
}

- (NSArray *)internationalShippingMethods {
    PKShippingMethod *normalItem =
        [PKShippingMethod summaryItemWithLabel:@"Llama International Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"40.00"]];
    normalItem.detail = @"3-5 Business Days";
    normalItem.identifier = normalItem.label;
    PKShippingMethod *expressItem =
        [PKShippingMethod summaryItemWithLabel:@"Llama International Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"50.00"]];
    expressItem.detail = @"Next Day";
    expressItem.identifier = expressItem.label;
    return @[normalItem, expressItem];
}

@end
