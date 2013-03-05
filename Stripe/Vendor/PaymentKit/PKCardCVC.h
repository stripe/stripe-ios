//
//  PKCardCVC.h
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PKCardType.h"

@interface PKCardCVC : NSObject

@property (nonatomic, readonly) NSString* string;

+ (id)cardCVCWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;
- (NSString*)string;
- (BOOL)isValid;
- (BOOL)isValidWithType:(PKCardType)type;
- (BOOL)isPartiallyValid;
- (BOOL)isPartiallyValidWithType:(PKCardType)type;

@end
