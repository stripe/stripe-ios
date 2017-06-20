//
//  STPSourceReceiver.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSDictionary+Stripe.h"
#import "STPSourceReceiver.h"

@interface STPSourceReceiver ()

@property (nonatomic, nullable) NSString *address;
@property (nonatomic, nullable) NSNumber *amountCharged;
@property (nonatomic, nullable) NSNumber *amountReceived;
@property (nonatomic, nullable) NSNumber *amountReturned;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPSourceReceiver

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Details (alphabetical)
                       [NSString stringWithFormat:@"address = %@", (self.address) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"amountCharged = %@", self.amountCharged],
                       [NSString stringWithFormat:@"amountReceived = %@", self.amountReceived],
                       [NSString stringWithFormat:@"amountReturned = %@", self.amountReturned],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[@"address"];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPSourceReceiver *receiver = [self new];
    receiver.allResponseFields = dict;
    receiver.address = dict[@"address"];
    receiver.amountCharged = dict[@"amount_charged"];
    receiver.amountReceived = dict[@"amount_received"];
    receiver.amountReturned = dict[@"amount_returned"];
    return receiver;
}

@end
