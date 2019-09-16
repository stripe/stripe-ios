//
//  STPAPIClient+ApplePay.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

#import "STPAPIClient+ApplePay.h"

#import "NSError+Stripe.h"
#import "PKPayment+Stripe.h"
#import "STPAPIClient+Private.h"
#import "STPAnalyticsClient.h"
#import "STPSourceParams.h"
#import "STPPaymentMethodAddress.h"
#import "STPPaymentMethodBillingDetails.h"
#import "STPPaymentMethodCardParams.h"
#import "STPPaymentMethodParams.h"
#import "STPTelemetryClient.h"
#import "STPToken.h"

@implementation STPAPIClient (ApplePay)

- (void)createTokenWithPayment:(PKPayment *)payment completion:(STPTokenCompletionBlock)completion {
    NSMutableDictionary *params = [[[self class] parametersForPayment:payment] mutableCopy];
    [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:params];
    [self createTokenWithParameters:params
                         completion:completion];
    [[STPTelemetryClient sharedInstance] sendTelemetryData];
}

- (void)createSourceWithPayment:(PKPayment *)payment completion:(STPSourceCompletionBlock)completion {
    NSCAssert(payment != nil, @"'payment' is required to create an apple pay source");
    NSCAssert(completion != nil, @"'completion' is required to use the source that is created");
    [self createTokenWithPayment:payment completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        if (token.tokenId == nil
            || error != nil) {
            completion(nil, error ?: [NSError stp_genericConnectionError]);
        } else {
            STPSourceParams *params = [STPSourceParams new];
            params.type = STPSourceTypeCard;
            params.token = token.tokenId;
            [self createSourceWithParams:params completion:completion];
        }
    }];
}

- (void)createPaymentMethodWithPayment:(PKPayment *)payment completion:(STPPaymentMethodCompletionBlock)completion {
    NSCAssert(payment != nil, @"'payment' is required to create an apple pay payment method");
    NSCAssert(completion != nil, @"'completion' is required to use the payment method that is created");
    [self createTokenWithPayment:payment completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        if (token.tokenId == nil
            || error != nil) {
            completion(nil, error ?: [NSError stp_genericConnectionError]);
        } else {
            STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
            cardParams.token = token.tokenId;
            STPPaymentMethodBillingDetails *billingDetails = [[self class] billingDetailsFromPKPayment:payment];
            STPPaymentMethodParams *paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams
                                                                                  billingDetails:billingDetails
                                                                                        metadata:nil];
            [self createPaymentMethodWithParams:paymentMethodParams completion:completion];
        }
    }];

}

+ (STPPaymentMethodBillingDetails *)billingDetailsFromPKPayment:(PKPayment *)payment {
    STPPaymentMethodBillingDetails *billingDetails = nil;
    if (payment.billingContact) {
        billingDetails = [[STPPaymentMethodBillingDetails alloc] init];
        STPAddress *billingAddress = [[STPAddress alloc] initWithPKContact:payment.billingContact];
        billingDetails.name = billingAddress.name;
        billingDetails.email = billingAddress.email;
        billingDetails.phone = billingAddress.phone;
        if (payment.billingContact.postalAddress) {
            billingDetails.address = [[STPPaymentMethodAddress alloc] initWithAddress:billingAddress];
        }
    }

    // The phone number and email in the "Contact" panel in the Apple Pay dialog go into the shippingContact,
    // not the billingContact. To work around this, we should fill the billingDetails' email and phone
    // number from the shippingDetails.
    if (payment.shippingContact) {
        STPAddress *shippingAddress = [[STPAddress alloc] initWithPKContact:payment.shippingContact];
        if (billingDetails.email == nil && shippingAddress.email != nil) {
            if (billingDetails == nil) {
                billingDetails = [[STPPaymentMethodBillingDetails alloc] init];
            }
            billingDetails.email = shippingAddress.email;
        }
        if (billingDetails.phone == nil && shippingAddress.phone != nil) {
            if (billingDetails == nil) {
                billingDetails = [[STPPaymentMethodBillingDetails alloc] init];
            }
            billingDetails.phone = shippingAddress.phone;
        }
    }
    
    return billingDetails;
}

+ (NSDictionary *)addressParamsFromPKContact:(PKContact *)contact {
    if (contact) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        STPAddress *stpAddress = [[STPAddress alloc] initWithPKContact:contact];
        
        params[@"name"] = stpAddress.name;
        params[@"address_line1"] = stpAddress.line1;
        params[@"address_city"] = stpAddress.city;
        params[@"address_state"] = stpAddress.state;
        params[@"address_zip"] = stpAddress.postalCode;
        params[@"address_country"] = stpAddress.country;

        return params;
    } else {
        return nil;
    }
}

+ (NSDictionary *)parametersForPayment:(PKPayment *)payment {
    NSCAssert(payment != nil, @"Cannot create a token with a nil payment.");

    NSString *paymentString = [[NSString alloc] initWithData:payment.token.paymentData encoding:NSUTF8StringEncoding];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    payload[@"pk_token"] = paymentString;
    payload[@"card"] = [self addressParamsFromPKContact:payment.billingContact];

    NSCAssert(!(paymentString.length == 0 && [[Stripe defaultPublishableKey] hasPrefix:@"pk_live"]), @"The pk_token is empty. Using Apple Pay with an iOS Simulator while not in Stripe Test Mode will always fail.");

    NSString *paymentInstrumentName = payment.token.paymentMethod.displayName;
    if (paymentInstrumentName) {
        payload[@"pk_token_instrument_name"] = paymentInstrumentName;
    }

    NSString *paymentNetwork = payment.token.paymentMethod.network;
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

#pragma mark - Errors

+ (NSError *)pkPaymentErrorForStripeError:(NSError *)stripeError {
    if (stripeError == nil) {
        return nil;
    }
    NSMutableDictionary *userInfo = [stripeError.userInfo mutableCopy];
    PKPaymentErrorCode errorCode = PKPaymentUnknownError;
    if (stripeError.domain == StripeDomain) {
        if ([stripeError.userInfo[STPCardErrorCodeKey] isEqualToString:STPIncorrectZip]) {
            errorCode = PKPaymentBillingContactInvalidError;
            userInfo[PKPaymentErrorPostalAddressUserInfoKey] = CNPostalAddressPostalCodeKey;
        }
    }
    return [NSError errorWithDomain:PKPaymentErrorDomain code:errorCode userInfo:userInfo];
}

@end

void linkSTPAPIClientApplePayCategory(void){}
