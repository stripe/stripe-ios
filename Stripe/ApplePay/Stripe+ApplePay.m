//
//  Stripe+ApplePay.m
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//
//

#if defined(STRIPE_ENABLE_APPLEPAY)

#import "Stripe.h"
#import "Stripe+ApplePay.h"
#import "STPAPIClient.h"
#import <AddressBook/AddressBook.h>

@implementation STPAPIClient (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest {
    if (paymentRequest == nil) {
        return NO;
    }
    return [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:paymentRequest.supportedNetworks];
}

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier {
    if (![PKPaymentRequest class]) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [PKPaymentRequest new];
    [paymentRequest setMerchantIdentifier:merchantIdentifier];
    [paymentRequest setSupportedNetworks:@[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]];
    [paymentRequest setMerchantCapabilities:PKMerchantCapability3DS];
    [paymentRequest setCountryCode:@"US"];
    [paymentRequest setCurrencyCode:@"USD"];
    return paymentRequest;
}

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

@implementation Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest {
    return [STPAPIClient canSubmitPaymentRequest:paymentRequest];
}

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier {
    return [STPAPIClient paymentRequestWithMerchantIdentifier:merchantIdentifier];
}

+ (void)createTokenWithPayment:(PKPayment *)payment completion:(STPCompletionBlock)handler {
    [self createTokenWithPayment:payment operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithPayment:(PKPayment *)payment operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler {
    STPAPIClient *client = [[STPAPIClient alloc] init];
    client.operationQueue = queue;
    [client createTokenWithPayment:payment completion:handler];
}

@end

#endif
