//
//  STPAPIClient+ApplePay.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

#import "STPAPIClient+ApplePay.h"

#if !TARGET_OS_WATCH
#import <AddressBook/AddressBook.h>
#endif

#import "PKPayment+Stripe.h"
#import "STPAPIClient+Private.h"
#import "STPAnalyticsClient.h"

FAUXPAS_IGNORED_IN_FILE(APIAvailability)

@implementation STPAPIClient (ApplePay)

- (void)createTokenWithPayment:(PKPayment *)payment completion:(STPTokenCompletionBlock)completion {
    NSDictionary *parameters = [[self class] parametersForPayment:payment];
    [self createTokenWithParameters:parameters
                         completion:completion];
}

#if !TARGET_OS_WATCH
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (NSDictionary *)addressParamsFromABRecord:(ABRecordRef)billingAddress {
    if (billingAddress) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];

        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(billingAddress, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(billingAddress, kABPersonLastNameProperty);
        if (firstName.length && lastName.length) {
            params[@"name"] = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        }

        ABMultiValueRef addressValues = ABRecordCopyValue(billingAddress, kABPersonAddressProperty);
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
            }
            CFRelease(addressValues);
        }
        return params;
    }
    else {
        return nil;
    }

}
#pragma clang diagnostic pop
#endif

+ (NSDictionary *)addressParamsFromPKContact:(PKContact *)billingContact {
    if (billingContact) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];

        NSPersonNameComponents *nameComponents = billingContact.name;
        if (nameComponents) {
            params[@"name"] = [NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:nameComponents
                                                                                       style:NSPersonNameComponentsFormatterStyleDefault
                                                                                     options:(NSPersonNameComponentsFormatterOptions)0];
        }

        CNPostalAddress *address = billingContact.postalAddress;
        if (address) {
            params[@"address_line1"] = address.street;
            params[@"address_city"] = address.city;
            params[@"address_state"] = address.state;
            params[@"address_zip"] = address.postalCode;
            params[@"address_country"] = address.ISOCountryCode;
        }

        return params;
    }
    else {
        return nil;
    }
}

+ (NSDictionary *)parametersForPayment:(PKPayment *)payment {
    NSCAssert(payment != nil, @"Cannot create a token with a nil payment.");
    NSString *paymentString =
    [[NSString alloc] initWithData:payment.token.paymentData encoding:NSUTF8StringEncoding];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    payload[@"pk_token"] = paymentString;

#if TARGET_OS_WATCH
    payload[@"card"] = [self addressParamsFromPKContact:payment.billingContact];
#else
    if ([PKContact class]
        && [payment respondsToSelector:@selector(billingContact)]) {
        payload[@"card"] = [self addressParamsFromPKContact:payment.billingContact];
    }
    else {
        payload[@"card"] = [self addressParamsFromABRecord:payment.billingAddress];
    }
#endif

    PKPaymentToken *token = payment.token;
    NSString *paymentInstrumentName = nil;
    NSString *paymentNetwork = nil;

#if TARGET_OS_WATCH
    paymentInstrumentName = token.paymentMethod.displayName;
    paymentNetwork = token.paymentMethod.network;
#else

    if ([token respondsToSelector:@selector(paymentMethod)]) {
        paymentInstrumentName = token.paymentMethod.displayName;
        paymentNetwork = token.paymentMethod.network;
    }
    else {
        paymentInstrumentName = token.paymentInstrumentName;
        paymentNetwork = token.paymentNetwork;
    }
#endif

    if (paymentInstrumentName) {
        payload[@"pk_token_instrument_name"] = paymentInstrumentName;
    }

    if (paymentNetwork) {
        payload[@"pk_token_payment_network"] = paymentNetwork;
    }

    NSString *transactionIdentifier = payment.token.transactionIdentifier;
    if (transactionIdentifier) {
        if ([payment stp_isSimulated]) {
            transactionIdentifier = [PKPayment stp_testTransactionIdentifier];
        }
        payload[@"pk_token_transaction_id"] = transactionIdentifier;
    }

    return payload;
}


@end

void linkSTPAPIClientApplePayCategory(void){}
