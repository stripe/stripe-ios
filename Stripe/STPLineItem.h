//
//  STPLineItem.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPLineItem : NSObject

- (instancetype)initWithLabel:(NSString *)label amount:(NSDecimalNumber *)amount;

@property(nonatomic, readonly) NSString *label;
@property(nonatomic, readonly) NSDecimalNumber *amount;

@end
