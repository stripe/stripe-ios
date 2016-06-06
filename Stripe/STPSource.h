//
//  STPSource.h
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol STPSource <NSObject>

@property(nonatomic, readonly, copy, nonnull)NSString *stripeID;
@property(nonatomic, readonly, copy, nonnull)NSString *label;
@property(nonatomic, readonly, nullable)UIImage *image;

@end
