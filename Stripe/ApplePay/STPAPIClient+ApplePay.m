//
//  STPAPIClient+ApplePay.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

#import "STPAPIClient+ApplePay.h"
#import <AddressBook/AddressBook.h>

@implementation STPAPIClient (ApplePay)

- (void)createTokenWithPayment:(PKPayment *)payment completion:(STPCompletionBlock)completion {
    [self createTokenWithData:[self.class formEncodedDataForPayment:payment] completion:completion];
}

+ (NSData *)formEncodedDataForPayment:(PKPayment *)payment {
    NSCAssert(payment != nil, @"Cannot create a token with a nil payment.");
    NSMutableCharacterSet *set = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [set removeCharactersInString:@"+="];
    NSString *paymentString =
        [[[NSString alloc] initWithData:payment.token.paymentData encoding:NSUTF8StringEncoding] stringByAddingPercentEncodingWithAllowedCharacters:set];
    __block NSString *payloadString = [@"pk_token=" stringByAppendingString:paymentString];

    if (payment.billingAddress) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        ABMultiValueRef addressValues = ABRecordCopyValue(payment.billingAddress, kABPersonAddressProperty);
        if (ABMultiValueGetCount(addressValues) > 0) {
            CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
            NSString *line1 = CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
            if (line1) {
                params[@"address_line1"] = line1;
            }
            NSString *city = CFDictionaryGetValue(dict, kABPersonAddressCityKey);
            if (city) {
                params[@"address_city"] = city;
            }
            NSString *state = CFDictionaryGetValue(dict, kABPersonAddressStateKey);
            if (state) {
                params[@"address_state"] = state;
            }
            NSString *zip = CFDictionaryGetValue(dict, kABPersonAddressZIPKey);
            if (zip) {
                params[@"address_zip"] = zip;
            }
            NSString *country = CFDictionaryGetValue(dict, kABPersonAddressCountryKey);
            if (country) {
                params[@"address_country"] = country;
            }
            CFRelease(dict);
            [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, __unused BOOL *stop) {
                NSString *param = [NSString stringWithFormat:@"&card[%@]=%@", key, [obj stringByAddingPercentEncodingWithAllowedCharacters:set]];
                payloadString = [payloadString stringByAppendingString:param];
            }];
        }
        CFRelease(addressValues);
    }

    return [payloadString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
