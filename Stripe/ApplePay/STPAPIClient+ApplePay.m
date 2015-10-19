//
//  STPAPIClient+ApplePay.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

#import <AddressBook/AddressBook.h>

#import "STPAPIClient+ApplePay.h"
#import "PKPayment+Stripe.h"
#import "STPAPIClient+Private.h"

@implementation STPAPIClient (ApplePay)

- (void)createTokenWithPayment:(PKPayment *)payment completion:(STPTokenCompletionBlock)completion {
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
        
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(payment.billingAddress, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(payment.billingAddress, kABPersonLastNameProperty);
        if (firstName.length && lastName.length) {
            params[@"name"] = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        }
        
        ABMultiValueRef addressValues = ABRecordCopyValue(payment.billingAddress, kABPersonAddressProperty);
        if (addressValues != NULL) {
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
    }

    if (payment.token.paymentInstrumentName) {
        NSString *param = [NSString stringWithFormat:@"&pk_token_instrument_name=%@", payment.token.paymentInstrumentName];
        payloadString = [payloadString stringByAppendingString:param];
    }

    if (payment.token.paymentNetwork) {
        NSString *param = [NSString stringWithFormat:@"&pk_token_payment_network=%@", payment.token.paymentNetwork];
        payloadString = [payloadString stringByAppendingString:param];
    }
    
    if (payment.token.transactionIdentifier) {
        NSString *transactionIdentifier = payment.token.transactionIdentifier;
        if ([payment stp_isSimulated]) {
            transactionIdentifier = [PKPayment stp_testTransactionIdentifier];
        }
        NSString *param = [NSString stringWithFormat:@"&pk_token_transaction_id=%@", transactionIdentifier];
        payloadString = [payloadString stringByAppendingString:param];
    }

    return [payloadString dataUsingEncoding:NSUTF8StringEncoding];
}

@end

void linkSTPAPIClientApplePayCategory(void){}
