//
//  PKPayment+Stripe.m
//  Stripe
//
//  Created by Ben Guo on 7/2/15.
//

#import "PKPayment+Stripe.h"

@implementation PKPayment (Stripe)

- (BOOL)isSimulated {
    return [self.token.transactionIdentifier isEqualToString:@"Simulated Identifier"];
}

- (void)setFakeTransactionIdentifier {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

    PKPaymentToken *token = [PKPaymentToken new];
    if ([token respondsToSelector:@selector(setTransactionIdentifier:)]) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        uuid = [uuid stringByReplacingOccurrencesOfString:@"~" withString:@""
                                                  options:0
                                                    range:NSMakeRange(0, uuid.length)];
        
        // Simulated cards don't have enough info yet. For now, use a fake Visa number
        NSString *number = @"4242424242424242";

        // Without the original PKPaymentRequest, we'll need to use fake data here.
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"20.00"];
        NSString *cents = [@([[amount decimalNumberByMultiplyingByPowerOf10:2] integerValue]) stringValue];
        NSString *currency = @"USD";
        NSString *identifier = [@[@"ApplePayStubs", number, cents, currency, uuid] componentsJoinedByString:@"~"];
        [token performSelector:@selector(setTransactionIdentifier:) withObject:identifier];
    }
    if ([self respondsToSelector:@selector(setToken:)]) {
        [self performSelector:@selector(setToken:) withObject:token];
    }
#pragma clang diagnostic pop
}

@end
