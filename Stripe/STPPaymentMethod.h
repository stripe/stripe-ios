//
//  STPPaymentMethod.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, STPPaymentMethodType) {
    STPPaymentMethodTypeApplePay = 1 << 0,
    STPPaymentMethodTypeCard = 1 << 1,
    STPPaymentMethodTypeAll = STPPaymentMethodTypeApplePay | STPPaymentMethodTypeCard
};

@protocol STPPaymentMethod <NSObject>

@property (nonatomic, readonly) STPPaymentMethodType type;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSString *label;

@end
