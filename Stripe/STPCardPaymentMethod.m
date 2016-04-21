//
//  STPCardPaymentMethod.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCardPaymentMethod.h"
#import "STPCard.h"

@interface STPCardPaymentMethod ()

@property (nonatomic, readwrite) STPCard *card;

@end

@implementation STPCardPaymentMethod

- (instancetype)initWithCard:(STPCard *)card {
    self = [super init];
    if (self) {
        _card = card;
    }
    return self;
}

- (UIImage *)image {
    return self.card.image;
}

- (NSString *)label {
    return self.card.label;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[STPCardPaymentMethod class]] && [((STPCardPaymentMethod *)object).card isEqual:self.card];
}

@end
