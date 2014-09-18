//
//  PTKCardCVC.h
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTKCardType.h"
#import "PTKComponent.h"

@interface PTKCardCVC : PTKComponent

@property (nonatomic, readonly) NSString *string;

+ (instancetype)cardCVCWithString:(NSString *)string;
- (BOOL)isValidWithType:(PTKCardType)type;
- (BOOL)isPartiallyValidWithType:(PTKCardType)type;

@end
