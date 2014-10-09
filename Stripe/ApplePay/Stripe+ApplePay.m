//
//  Stripe+ApplePay.m
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && defined(STRIPE_ENABLE_APPLEPAY)

#import "Stripe.h"
#import "Stripe+ApplePay.h"
#import "STPAPIConnection.h"
#import <PassKit/PassKit.h>

@implementation Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest {
    if (paymentRequest == nil) {
        return NO;
    }
    return [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:paymentRequest.supportedNetworks];
}

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier
                                                    amount:(NSDecimalNumber *)amount
                                                  currency:(NSString *)currency
                                               description:(NSString *)description {
    if (![PKPaymentRequest class]) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [PKPaymentRequest new];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:description amount:amount];
    [paymentRequest setMerchantIdentifier:merchantIdentifier];
    [paymentRequest setSupportedNetworks:@[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]];
    [paymentRequest setMerchantCapabilities:PKMerchantCapability3DS];
    [paymentRequest setCountryCode:@"US"];
    [paymentRequest setCurrencyCode:currency];
    [paymentRequest setPaymentSummaryItems:@[totalItem]];
    return paymentRequest;
}

+ (void)createTokenWithPayment:(PKPayment *)payment
                    completion:(STPCompletionBlock)handler {
    [self createTokenWithPayment:payment
                  operationQueue:[NSOperationQueue mainQueue]
                      completion:handler];
}

+ (void)createTokenWithPayment:(PKPayment *)payment
                operationQueue:(NSOperationQueue *)queue
                    completion:(STPCompletionBlock)handler {
    
    if (handler == nil) {
        [NSException raise:@"RequiredParameter" format:@"'handler' is required to use the token that is created"];
    }
    
    NSURL *url = [self apiURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSData *userAgentData = [NSJSONSerialization dataWithJSONObject:[self stripeUserAgentDetails]
                                                            options:0
                                                              error:nil];
    NSString *userAgentDetails = [[NSString alloc] initWithData:userAgentData
                                                       encoding:NSUTF8StringEncoding];
    [request setValue:userAgentDetails forHTTPHeaderField:@"X-Stripe-User-Agent"];
    [request setValue:[@"Bearer " stringByAppendingString:[self defaultPublishableKey]] forHTTPHeaderField:@"Authorization"];
    
    NSMutableCharacterSet *set = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [set removeCharactersInString:@"+="];
    NSString *paymentString = [[[NSString alloc] initWithData:payment.token.paymentData encoding:NSUTF8StringEncoding] stringByAddingPercentEncodingWithAllowedCharacters:set];
    NSString *payloadString = [@"pk_token=" stringByAppendingString:paymentString];
    request.HTTPBody = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    [[[STPAPIConnection alloc] initWithRequest:request] runOnOperationQueue:queue
                                                                 completion:^(NSURLResponse *response, NSData *body, NSError *requestError) {
                                                                     [self handleTokenResponse:response body:body error:requestError completion:handler];
                                                                 }];
}

+ (BOOL) isSimulatorBuild {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

@end

#endif
