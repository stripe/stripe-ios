//
//  STPShippingMethod.h
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

/**
 *  These values control the labels used in the shipping info collection form.
 */
typedef NS_ENUM(NSUInteger, STPShippingType) {
    /**
     *  Shipping the purchase to the provided address using a third-party
     *  shipping company.
     */
    STPShippingTypeShipping,
    /**
     *  Delivering the purchase by the seller.
     */
    STPShippingTypeDelivery,
};

NS_ASSUME_NONNULL_BEGIN

@interface STPShippingMethod : NSObject

/**
 *  The shipping method's amount.
 */
@property (nonatomic) NSInteger amount;

/**
 *  The shipping method's currency.
 */
@property (nonatomic) NSString *currency;

/**
 *  A short, localized description of the shipping method.
 */
@property(nonatomic, copy) NSString *label;

/**
 *  A short, localized description of the shipping method's details.
 *  Use this property to differentiate the shipping methods you offer. 
 *  For example “Ships in 24 hours.” or “Arrives by 5pm on July 29.” 
 *  Don’t repeat the content of the label property.
 */
@property(nonatomic, copy) NSString *detail;

/**
 *  A unique identifier for the shipping method, used by the app.
 */
@property(nonatomic, copy) NSString *identifier;

- (instancetype)initWithAmount:(NSInteger)amount
                      currency:(nonnull NSString *)currency
                         label:(nonnull NSString *)label
                        detail:(nonnull NSString *)detail
                    identifier:(nonnull NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
