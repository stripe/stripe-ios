//
//  STPCheckoutOptions.h
//  StripeExample
//
//  Created by Jack Flintermann on 10/6/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface STPCheckoutOptions : NSObject

// required property
@property(nonatomic) NSString *publishableKey;

// strongly recommended properties
@property(nonatomic) UIImage *logoImage;
@property(nonatomic) NSURL *logoImageURL;
@property(nonatomic) UIColor *headerBackgroundColor;
@property(nonatomic) NSString *companyName;
@property(nonatomic) NSString *productDescription;
@property(nonatomic) NSUInteger purchaseAmount;

// optional properties
@property(nonatomic) NSString *currency;
@property(nonatomic) NSString *panelLabel;
@property(nonatomic) BOOL validateZipCode;
@property(nonatomic) NSString *customerEmail;
@property(nonatomic) BOOL allowRememberMe;

- (NSString *)stringifiedJavaScriptRepresentation;

@end
