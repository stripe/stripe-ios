//
//  PTKCardExpiry.h
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTKComponent.h"

@interface PTKCardExpiry : PTKComponent

@property (nonatomic, readonly) NSUInteger month;
@property (nonatomic, readonly) NSUInteger year;
@property (nonatomic, readonly) NSString *formattedString;
@property (nonatomic, readonly) NSString *formattedStringWithTrail;

+ (instancetype)cardExpiryWithString:(NSString *)string;
- (instancetype)initWithString:(NSString *)string;
- (BOOL)isValidLength;
- (BOOL)isValidDate;

@end
