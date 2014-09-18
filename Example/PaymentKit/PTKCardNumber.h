//
//  CardNumber.h
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTKCardType.h"
#import "PTKComponent.h"

@interface PTKCardNumber : PTKComponent

@property (nonatomic, readonly) PTKCardType cardType;
@property (nonatomic, readonly) NSString *last4;
@property (nonatomic, readonly) NSString *lastGroup;
@property (nonatomic, readonly) NSString *string;
@property (nonatomic, readonly) NSString *formattedString;
@property (nonatomic, readonly) NSString *formattedStringWithTrail;

@property (nonatomic, readonly, getter = isValid) BOOL valid;
@property (nonatomic, readonly, getter = isValidLength) BOOL validLength;
@property (nonatomic, readonly, getter = isValidLuhn) BOOL validLuhn;
@property (nonatomic, readonly, getter = isPartiallyValid) BOOL partiallyValid;

+ (instancetype)cardNumberWithString:(NSString *)string;
- (instancetype)initWithString:(NSString *)string;

@end
