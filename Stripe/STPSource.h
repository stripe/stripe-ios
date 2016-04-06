//
//  STPSource.h
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#define STPImageType UIImage
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#define STPImageType NSImage
#endif

@protocol STPSource <NSObject>

@property(nonatomic, readonly, copy, nonnull)NSString *stripeID;
@property(nonatomic, readonly, copy, nonnull)NSString *label;
@property(nonatomic, readonly, nullable)STPImageType *image;

@end
