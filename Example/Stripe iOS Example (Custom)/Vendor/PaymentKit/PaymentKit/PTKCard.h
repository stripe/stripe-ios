//
//  PTKCard.h
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/31/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PTKCard : NSObject

@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *cvc;
@property (nonatomic, copy) NSString *addressZip;
@property (nonatomic, assign) NSUInteger expMonth;
@property (nonatomic, assign) NSUInteger expYear;

@property (nonatomic, readonly) NSString *last4;

@end
