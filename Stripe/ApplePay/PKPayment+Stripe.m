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

- (void)setFakeTransactionIdentifierWithRequest:(PKPaymentRequest *)request {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    if ([self.token respondsToSelector:@selector(setTransactionIdentifier:)]) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        uuid = [uuid stringByReplacingOccurrencesOfString:@"~" withString:@""
                                                  options:0
                                                    range:NSMakeRange(0, uuid.length)];
        
        // Simulated cards don't have enough info yet. For now, use a fake Visa number
        NSString *number = @"4242424242424242";
        PKPaymentSummaryItem *lastSummaryItem = [request.paymentSummaryItems lastObject];
        NSDecimalNumber *amount = lastSummaryItem.amount;
        NSString *cents = [@([[amount decimalNumberByMultiplyingByPowerOf10:2] integerValue]) stringValue];
        NSString *currency = request.currencyCode;
        NSString *identifier = [@[@"ApplePayStubs", number, cents, currency, uuid] componentsJoinedByString:@"~"];
        [self.token performSelector:@selector(setTransactionIdentifier:) withObject:identifier];
    }
    
#pragma clang diagnostic pop
}

@end
